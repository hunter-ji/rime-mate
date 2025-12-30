package util

import (
	"os"

	"github.com/goccy/go-yaml"
)

func ReadYamlFile(filePath string) (config yaml.MapSlice, patchSlice yaml.MapSlice, patchIndex int, err error) {
	patchIndex = -1

	if _, err := os.Stat(filePath); err == nil {
		data, err := os.ReadFile(filePath)
		if err != nil {
			return config, patchSlice, patchIndex, err
		}
		Info("已获取到文件: " + filePath)

		if err := yaml.Unmarshal(data, &config); err != nil {
			return config, patchSlice, patchIndex, err
		}
		Info("配置文件解析成功")
	} else {
		Info("配置文件不存在: " + filePath)
		config = yaml.MapSlice{}
	}

	// 查找 patch 字段
	for i, item := range config {
		if key, ok := item.Key.(string); ok && key == "patch" {
			patchIndex = i
			// 尝试将其转换为 MapSlice
			if ps, ok := item.Value.(yaml.MapSlice); ok {
				patchSlice = ps
			} else if pm, ok := item.Value.(map[string]any); ok {
				// 如果是 map，转换为 slice (顺序可能会乱，但能工作)
				for k, v := range pm {
					patchSlice = append(patchSlice, yaml.MapItem{Key: k, Value: v})
				}
			} else if pm, ok := item.Value.(map[any]any); ok {
				for k, v := range pm {
					patchSlice = append(patchSlice, yaml.MapItem{Key: k, Value: v})
				}
			}
			break
		}
	}

	return config, patchSlice, patchIndex, nil
}
