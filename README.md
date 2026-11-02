# CBSFilter 🔍

> **Filtro e analisador de alta performance para logs CBS (Component-Based Servicing) do Windows.**

O **CBSFilter** é uma ferramenta desenvolvida em PowerShell para facilitar a análise e o diagnóstico de falhas em atualizações do Windows Update, corrupção de componentes do sistema (`sfc /scannow`, `DISM`) e erros em pacotes do Windows (`CBS.log` e arquivos rotacionados `CbsPersist_*.log`).

---

## 🚀 Principais Recursos

- **⚡ Processamento em Streaming de Alta Performance**: Utiliza Streams nativos do .NET (`FileStream`, `StreamReader`, `StreamWriter`), processando centenas de milhares de linhas em segundos com menos de 30 MB de RAM.
- **🛡️ Leitura Sem Bloqueio de Concorrência**: Lê o `CBS.log` ativo do sistema sem conflitar com o serviço `TrustedInstaller` (`FileShare.ReadWrite`).
- **🖥️ Interface Gráfica Moderna (GUI)**: Interface Windows Forms organizada, com suporte a estilos visuais modernos, presets rápidos de erro e atalho para carregar o log oficial do sistema com 1 clique.
- **💻 Suporte a Modo Linha de Comando (CLI)**: Permite automação via terminal ou scripts agendados com parâmetros customizáveis.
- **✨ Preservação de Palavras-Chave**: Permite combinar checkboxes rápidas com termos personalizados (códigos HRESULT como `0x800f081f`, nomes de pacotes, etc.) sem perda de digitação.
- **📂 Abertura Imediata do Resultado**: Pergunta ao final se deseja abrir o arquivo gerado no Bloco de Notas ou visualizador padrão.

---

## 🏛️ Arquitetura (Clean Code & Separation of Concerns)

O projeto segue os princípios de **Clean Code** e separação de responsabilidades (SoC):

```
CBSFilter/
├── CBSFilter.ps1             # Ponto de entrada (Controller: detecta CLI ou GUI)
├── src/
│   ├── Core/
│   │   └── LogFilterEngine.ps1  # Camada de Domínio / Regras de Negócio e Streaming I/O
│   └── UI/
│       └── MainForm.ps1         # Camada de Apresentação (Interface Windows Forms)
├── tests/
│   └── test_engine.ps1          # Suíte de Testes Automatizados da Engine
├── .gitignore                # Arquivos ignorados pelo Git
└── README.md                 # Documentação do projeto
```

- **`src/Core/LogFilterEngine.ps1`**: Contém a lógica de negócio pura, isolada de qualquer biblioteca gráfica. Realiza validação de caminhos, sanitização de filtros, compilação segura de expressões regulares (com escape para caracteres especiais) e gravação de metadados.
- **`src/UI/MainForm.ps1`**: Responsável exclusivamente pela interação com o usuário, validações de formulário, feedback visual e eventos de tela.
- **`CBSFilter.ps1`**: Atua como orquestrador e ponto único de entrada para o usuário, permitindo o uso tanto interativo (GUI) quanto automatizado (CLI).

---

## 📋 Pré-requisitos

- **Sistema Operacional**: Windows 10, Windows 11, Windows Server 2016 ou superior.
- **PowerShell**: Windows PowerShell 5.1 ou PowerShell 7+.
- **Privilégios**: Para ler diretamente `C:\Windows\Logs\CBS\CBS.log`, execute o PowerShell como **Administrador**.

---

## 📖 Como Usar

### 1. Modo Gráfico (GUI)

Basta executar o script principal no PowerShell:

```powershell
.\CBSFilter.ps1
```

1. Clique em **"CBS Padrão"** para apontar para o log oficial do Windows ou em **"Procurar..."** para carregar um arquivo específico.
2. Selecione os presets desejados (*Error*, *Warning*, *Rollback*, *Critical*, etc.) ou digite suas palavras-chave na caixa de texto.
3. Clique em **"Iniciar Filtragem"**.
4. Ao término, o resumo de linhas encontradas será exibido e você poderá abrir o relatório diretamente.

---

### 2. Modo Linha de Comando (CLI)

Ideal para scripts de diagnóstico remoto ou automações de suporte:

```powershell
# Exemplo 1: Filtrar erros e rollbacks do CBS padrão do sistema
.\CBSFilter.ps1 -Keywords "Error", "Rollback" -NoGui

# Exemplo 2: Filtrar códigos de erro específicos em um log de backup
.\CBSFilter.ps1 -CbsLogPath "D:\Logs\CbsPersist_20261101.log" -Keywords "0x800f081f, Failed" -OutputPath "D:\resultado.log" -NoGui
```

#### Parâmetros Disponíveis

| Parâmetro | Tipo | Descrição |
| :--- | :--- | :--- |
| `-CbsLogPath` | `string` | Caminho do arquivo de log. Padrão: `C:\Windows\Logs\CBS\CBS.log`. |
| `-Keywords` | `string[]` | Lista ou sequência de palavras-chave a serem filtradas. |
| `-OutputPath` | `string` | Caminho de destino do arquivo filtrado. Padrão: Desktop com timestamp. |
| `-CaseSensitive` | `switch` | Se informado, diferencia maiúsculas de minúsculas. |
| `-NoGui` | `switch` | Força a execução puramente em linha de comando. |

---

## 🧪 Testes Automatizados

Para executar os testes unitários do mecanismo de filtragem e validação sintática:

```powershell
# Testes de unidade da engine
powershell -ExecutionPolicy Bypass -File .\tests\test_engine.ps1

# Verificação de sintaxe de todos os scripts
powershell -ExecutionPolicy Bypass -File .\tests\verify_syntax.ps1
```

---

## 🔄 Histórico de Atualizações (Changelog)

### Versão 2.0 (2026) - Grande Atualização e Refatoração (3 anos após v1.0)
- **Clean Code Architecture**: Separação clara entre Camada de Domínio/Streaming (`src/Core`), Camada de Apresentação (`src/UI`) e Controlador de Entrada (`CBSFilter.ps1`).
- **Engine em Streaming (.NET)**: Substituição do `Get-Content` por Streams nativos com `FileShare.ReadWrite`, permitindo processar logs de centenas de MBs em segundos sem travar a interface e consumindo menos de 30 MB de RAM.
- **Suporte a CLI**: Possibilidade de rodar o script sem interface gráfica para tarefas automatizadas.
- **Correção da Interface Gráfica**:
  - Correção de controles sobrepostos e layout simétrico.
  - Sincronização inteligente dos presets com preservação de palavras-chave manuais.
  - Habilitação de estilos visuais nativos modernos.
  - Pergunta automática para abrir o arquivo gerado ao final.
- **Qualidade & Testes**: Inclusão de suíte de testes automatizados e arquivo `.gitignore`.

---

## 📝 Licença

Distribuído sob a licença MIT. Sinta-se livre para utilizar, modificar e contribuir!
