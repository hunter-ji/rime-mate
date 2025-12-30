package ohMyRime

import (
	"fmt"
	"os"
	"path/filepath"
	"rime-mate/util"

	"github.com/goccy/go-yaml"
)

func InstallLangModel() error {
	basePath := util.TransformPath("~/Library/Rime/")
	downloadedModelPath := filepath.Join(basePath, "wanxiang-lts-zh-hans.gram")
	rimeMintCustomYamlPath := filepath.Join(basePath, "rime_mint.custom.yaml")

	util.Info("正在下载语言模型文件，这可能需要一点时间...")
	// 下载语言模型
	var err = util.DownloadResource(
		LMDG_GITHUB_URL,
		LMDG_CNB_URL,
		downloadedModelPath,
	)

	if err != nil {
		return err
	}
	util.Info("语言模型文件下载完成。")

	util.Info("正在更新 Rime 配置...")
	// 更新配置文件, 在 ~/Library/Rime/rime_mint.custom.yaml 中添加：
	// configPath := os.ExpandEnv(rimeMintCustomYamlPath)

	// 读取或创建配置文件
	var config yaml.MapSlice
	if _, err := os.Stat(rimeMintCustomYamlPath); err == nil {
		data, err := os.ReadFile(rimeMintCustomYamlPath)
		if err != nil {
			return err
		}
		util.Info("已获取到文件: " + rimeMintCustomYamlPath)

		if err := yaml.Unmarshal(data, &config); err != nil {
			return err
		}
		util.Info("配置文件解析成功")
	} else {
		util.Info("配置文件不存在，将创建新文件: " + rimeMintCustomYamlPath)
		config = yaml.MapSlice{}
	}

	// 查找 patch 字段
	var patchSlice yaml.MapSlice
	patchIndex := -1

	for i, item := range config {
		if key, ok := item.Key.(string); ok && key == "patch" {
			patchIndex = i
			// 尝试将其转换为 MapSlice
			if ps, ok := item.Value.(yaml.MapSlice); ok {
				patchSlice = ps
			} else if pm, ok := item.Value.(map[string]interface{}); ok {
				// 如果是 map，转换为 slice (顺序可能会乱，但能工作)
				for k, v := range pm {
					patchSlice = append(patchSlice, yaml.MapItem{Key: k, Value: v})
				}
			} else if pm, ok := item.Value.(map[interface{}]interface{}); ok {
				for k, v := range pm {
					patchSlice = append(patchSlice, yaml.MapItem{Key: k, Value: v})
				}
			}
			break
		}
	}

	// 定义需要添加的配置项 (使用切片保持顺序)
	updates := []struct {
		Key   string
		Value interface{}
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
