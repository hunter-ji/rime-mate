package main

import (
	"fmt"
	"os"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"

	"rime-mate/modules/ohMyRime"
)

// Styles
var (
	titleStyle    = lipgloss.NewStyle().Foreground(lipgloss.Color("#04B575")).Bold(true).MarginBottom(1).MarginTop(1)
	itemStyle     = lipgloss.NewStyle().PaddingLeft(2)
	selectedStyle = lipgloss.NewStyle().PaddingLeft(0).Foreground(lipgloss.Color("#FF7AB2")).Bold(true)
	disabledStyle = lipgloss.NewStyle().PaddingLeft(2).Foreground(lipgloss.Color("#626262"))
	helpStyle     = lipgloss.NewStyle().Foreground(lipgloss.Color("#626262")).MarginTop(1)
)

// Application State
type sessionState int

const (
	viewMain sessionState = iota
	viewMint
)

type item struct {
	title    string
	disabled bool
}

type model struct {
	state    sessionState
	cursor   int
	mainMenu []item
	mintMenu []item
	choice   string // To store the final choice for main()
}

func initialModel() model {
	return model{
		state:  viewMain,
		cursor: 1, // Default to "薄荷输入法" since the first one is disabled
		mainMenu: []item{
			{title: "雾凇拼音 (即将到来)", disabled: true},
			{title: "薄荷输入法", disabled: false},
			{title: "退出", disabled: false},
		},
		mintMenu: []item{
			{title: "安装 (即将到来)", disabled: true},
			{title: "安装万象语言模型", disabled: false},
			{title: "配置 (即将到来)", disabled: true},
			{title: "返回", disabled: false},
		},
	}
}

func (m model) Init() tea.Cmd {
	return nil
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	var currentMenu []item
	if m.state == viewMain {
		currentMenu = m.mainMenu
	} else {
		currentMenu = m.mintMenu
	}

	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "ctrl+c", "q":
			return m, tea.Quit

		case "up", "k":
			if m.cursor > 0 {
				m.cursor--
			}

		case "down", "j":
			if m.cursor < len(currentMenu)-1 {
				m.cursor++
			}

		case "enter":
			selectedItem := currentMenu[m.cursor]
			if selectedItem.disabled {
				return m, nil
			}

			switch m.state {
			case viewMain:
				switch selectedItem.title {
				case "薄荷输入法":
					m.state = viewMint
					m.cursor = 1 // Default to "安装万象语言模型"
				case "退出":
					return m, tea.Quit
				}
			case viewMint:
				switch selectedItem.title {
				case "返回":
					m.state = viewMain
					m.cursor = 1 // Reset cursor to Mint option
				case "安装万象语言模型":
					m.choice = "install_wanxiang"
					return m, tea.Quit
				}
			}
		}
	}
	return m, nil
}

func (m model) View() string {
	var s string
	var currentMenu []item

	if m.state == viewMain {
		s = titleStyle.Render("Rime Mate") + "\n"
		currentMenu = m.mainMenu
	} else {
		s = titleStyle.Render("薄荷输入法配置") + "\n"
		currentMenu = m.mintMenu
	}

	for i, choice := range currentMenu {
		cursor := "  "
		if m.cursor == i {
			cursor = "> "
			s += selectedStyle.Render(fmt.Sprintf("%s%s", cursor, choice.title)) + "\n"
		} else {
			if choice.disabled {
				s += disabledStyle.Render(choice.title) + "\n"
			} else {
				s += itemStyle.Render(choice.title) + "\n"
			}
		}
	}

	s += helpStyle.Render("↑/↓ 选择 • 回车 确认 • q 退出") + "\n"
	return s
}

func handleActions() {
	p := tea.NewProgram(initialModel())
	finalModel, err := p.Run()

	if err != nil {
		fmt.Printf("❌ 错误: %v\n", err)
		os.Exit(1)
	}

	m := finalModel.(model)
	if m.choice == "install_wanxiang" {
		fmt.Println("\n🚀 正在准备安装万象语言模型...")

		// 调用安装函数
		if installError := ohMyRime.InstallLangModel(); installError != nil {
			fmt.Printf("❌ 安装失败: %v\n", installError)
			os.Exit(1)
		}

		fmt.Println("✅ 万象语言模型安装完成！请重新部署输入法以应用更改。")
	}
}
