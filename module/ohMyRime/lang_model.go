package ohMyRime

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"rime-mate/util"
	"runtime"
	"slices"
	"strings"

	"github.com/goccy/go-yaml"
)

func loadResourceURLs() (string, string) {
	rimeDir, err := getCrossPlatformRimeDir()
	if err != nil {
		util.Error("获取 Rime 配置目录失败: " + err.Error())
		os.Exit(1)
	}

	langModelPath := filepath.Join(rimeDir, "wanxiang-lts-zh-hans.gram")
	rimeMintCustomYamlPath := filepath.Join(rimeDir, "rime_mint.custom.yaml")

	return langModelPath, rimeMintCustomYamlPath
}

func getCrossPlatformRimeDir() (string, error) {
	home, err := os.UserHomeDir()
	if err != nil {
		return "", err
	}

	switch runtime.GOOS {
	case "darwin":
		path := filepath.Join(home, "Library/Rime")
		if _, err := os.Stat(path); err == nil {
			return path, nil
		}
		return "", fmt.Errorf("未找到 macOS 下的 Rime 配置目录")
	case "linux":
		paths := []string{
			filepath.Join(home, ".config/ibus/rime"),
			filepath.Join(home, ".local/share/fcitx5/rime"),
		}
		for _, p := range paths {
			if _, err := os.Stat(p); err == nil {
				return p, nil
			}
		}
		return "", fmt.Errorf("未找到 Linux 下的 Rime 配置目录，请检查是否安装 iBus-Rime/Fcitx5-Rime")
	case "windows":
		cmd := exec.Command(
			"reg",
			"query",
			`HKCU\Software\Rime\Weasel`,
			"/v",
			"RimeUserDir",
		)
		output, err := cmd.Output()
		if err == nil {
			fields := strings.Fields(string(output))
			if len(fields) > 0 {
				regPath := fields[len(fields)-1]
				if _, err := os.Stat(regPath); err == nil {
					return regPath, nil
				}
			}
		}

		path := filepath.Join(home, "AppData", "Roaming", "Rime")
		if _, err := os.Stat(path); err == nil {
			return path, nil
		}

		return "", fmt.Errorf("未找到 Windows 下的小狼毫 (Weasel) Rime 配置目录")
	default:
		return "", fmt.Errorf("不支持的系统: %s", runtime.GOOS)
	}
}

func InstallLangModel() error {
	langModelPath, rimeMintCustomYamlPath := loadResourceURLs()

	util.Info("正在下载语言模型文件，这可能需要一点时间...")
	var err = util.DownloadResource(
		LMDG_GITHUB_URL,
		LMDG_CNB_URL,
		langModelPath,
	)

	if err != nil {
		return err
	}
	util.Info("语言模型文件下载完成。")

	util.Info("正在更新 Rime 配置...")

	// 读取配置文件
	config, patchSlice, patchIndex, err := util.ReadYamlFile(rimeMintCustomYamlPath)
	if err != nil {
		return err
	}

	// 定义需要添加的配置项 (使用切片保持顺序)
	updates := []struct {
		Key   string
		Value any
	}{
		{"grammar/language", "wanxiang-lts-zh-hans"},
		{"grammar/collocation_max_length", 5},
		{"grammar/collocation_min_length", 2},
		{"translator/contextual_suggestions", true},
		{"translator/max_homophones", 7},
		{"translator/max_homographs", 7},
	}

	// 仅当配置不存在时才添加，避免覆盖用户原有配置
	for _, update := range updates {
		exists := false
		for _, item := range patchSlice {
			if key, ok := item.Key.(string); ok && key == update.Key {
				exists = true
				break
			}
		}

		if !exists {
			patchSlice = append(patchSlice, yaml.MapItem{Key: update.Key, Value: update.Value})
			util.Info("添加配置: " + update.Key + " = " + fmt.Sprintf("%v", update.Value))
		}
	}

	// 更新 config 中的 patch
	if patchIndex != -1 {
		config[patchIndex].Value = patchSlice
	} else {
		config = append(config, yaml.MapItem{Key: "patch", Value: patchSlice})
	}

	// 写入文件
	data, err := yaml.Marshal(config)
	if err != nil {
		return err
	}

	err = os.WriteFile(rimeMintCustomYamlPath, data, 0644)
	if err == nil {
		util.Info("配置更新成功！")
	}
	return err
}

func RemoveLangModel() error {
	langModelPath, rimeMintCustomYamlPath := loadResourceURLs()

	util.Info("正在删除语言模型文件...")
	// 删除语言模型文件
	if _, err := os.Stat(langModelPath); err == nil {
		if err := os.Remove(langModelPath); err != nil {
			util.Error("删除语言模型文件失败: " + err.Error())
		} else {
			util.Info("语言模型文件已删除: " + langModelPath)
		}
	} else {
		util.Info("语言模型文件不存在，跳过删除。")
	}

	util.Info("正在清理 Rime 配置...")

	// 读取配置文件
	config, patchSlice, patchIndex, err := util.ReadYamlFile(rimeMintCustomYamlPath)
	if err != nil {
		return err
	}

	if patchIndex == -1 {
		util.Info("配置文件中未找到 patch 字段，无需清理。")
		return nil
	}

	// 定义需要移除的配置项 Key
	keysToRemove := []string{
		"grammar/language",
		"grammar/collocation_max_length",
		"grammar/collocation_min_length",
		"translator/contextual_suggestions",
		"translator/max_homophones",
		"translator/max_homographs",
	}

	// 过滤掉需要移除的配置项
	var newPatchSlice yaml.MapSlice
	removedCount := 0
	for _, item := range patchSlice {
		shouldRemove := false
		if key, ok := item.Key.(string); ok {
			if slices.Contains(keysToRemove, key) {
				shouldRemove = true
			}
		}
		if !shouldRemove {
			newPatchSlice = append(newPatchSlice, item)
		} else {
			removedCount++
			util.Info("移除配置: " + fmt.Sprintf("%v", item.Key))
		}
	}

	if removedCount == 0 {
		util.Info("未发现相关配置项，无需更新文件。")
		return nil
	}

	if len(newPatchSlice) == 0 {
		// 如果 patch 为空，则从 config 中移除 patch 字段
		config = append(config[:patchIndex], config[patchIndex+1:]...)
	} else {
		// 更新 config 中的 patch
		config[patchIndex].Value = newPatchSlice
	}

	// 写入文件
	var data []byte
	if len(config) > 0 {
		data, err = yaml.Marshal(config)
		if err != nil {
			return err
		}
	}

	err = os.WriteFile(rimeMintCustomYamlPath, data, 0644)
	if err == nil {
		util.Info("配置清理成功！")
	}
	return err
}
