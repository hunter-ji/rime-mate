package util

import (
	"os"
	"path/filepath"
	"strings"
)

// TransformPath 展开路径中的 ~ 为用户主目录。
//
// 参数:
//
// path: 包含可能的 ~ 的路径字符串。
//
// 返回:
//
// string: 展开后的路径字符串。
func TransformPath(path string) string {
	// 如果路径以 ~/ 开头，展开为用户主目录
	if strings.HasPrefix(path, "~/") {
		home, err := os.UserHomeDir()
		if err != nil {
			return path
		}
		path = filepath.Join(home, path[2:])
	}
	return path
}
