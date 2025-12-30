package util

import (
	"fmt"
	"io"
	"net/http"
	"os"
)

// DownloadResource 从指定的 URL 下载文件到 destPath。
// 优先尝试 urlCNB (非 GitHub 链接)，如果失败或为空，则尝试 urlGitHub。
//
// 参数:
//
//	urlGitHub: GitHub 资源的下载链接，作为备选方案。
//	urlCNB:    CNB (或其他国内源) 资源的下载链接，作为优先方案。
//	destPath:  文件保存的完整本地路径（包含文件名）。
//
// 返回:
//
//	error: 如果所有尝试都失败，返回错误信息。
func DownloadResource(urlGitHub string, urlCNB string, destPath string) error {
	var err error

	// 尝试优先下载 CNB 链接
	if urlCNB != "" {
		err = downloadFile(urlCNB, destPath)
		if err == nil {
			return nil
		}
		fmt.Printf("Failed to download from CNB (%s): %v. Trying GitHub...\n", urlCNB, err)
	}

	// 如果 CNB 失败或为空，尝试 GitHub 链接
	if urlGitHub != "" {
		return downloadFile(urlGitHub, destPath)
	}

	if err != nil {
		return fmt.Errorf("all download attempts failed, last error: %w", err)
	}
	return fmt.Errorf("no valid URLs provided")
}

// downloadFile 执行实际的 HTTP GET 请求并将响应体写入文件。
//
// 参数:
//
//	url:      要下载的文件的 URL。
//	destPath: 文件保存的完整本地路径（包含文件名）。
func downloadFile(url string, destPath string) error {
	destPath = TransformPath(destPath)

	resp, err := http.Get(url)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("bad status: %s", resp.Status)
	}

	out, err := os.Create(destPath)
	if err != nil {
		return err
	}
	defer out.Close()

	_, err = io.Copy(out, resp.Body)
	return err
}
