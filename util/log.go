package util

import "fmt"

const (
	Reset = "\033[0m"
	Red   = "\033[31m"
	Green = "\033[32m"
	Gray  = "\033[90m"
	Bold  = "\033[1m"
)

func Info(message string) {
	fmt.Printf("%s%s%s\n", Gray, message, Reset)
}

func Error(message string) {
	fmt.Printf("%s%s❌  %s%s\n", Red, Bold, message, Reset)
}

func Success(message string) {
	fmt.Printf("%s%s%s%s\n", Green, Bold, message, Reset)
}
