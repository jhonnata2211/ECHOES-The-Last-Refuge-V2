# ECHOES: The Last Refuge — Instruções do projeto

Estas instruções se aplicam a todo o projeto.

## Identidade e plataformas

- Nome do projeto: ECHOES: The Last Refuge.
- Engine: Godot 4.x.
- Projeto 2D.
- Plataformas principais: Android e PC/Steam.
- Manter uma única base de código sempre que possível.
- Priorizar compatibilidade e desempenho em dispositivos Android.
- Utilizar GL Compatibility enquanto não houver motivo técnico aprovado para mudança.
- Preservar compatibilidade futura com touchscreen, teclado/mouse e gamepad.

## Organização e segurança

- Organizar cenas e scripts de forma modular, com responsabilidades claras.
- Evitar arquivos gigantes e sistemas excessivamente acoplados.
- Não adicionar plugins, dependências externas ou addons sem aprovação do diretor do projeto.
- Não alterar a arquitetura central sem aprovação do diretor do projeto.
- Não substituir sistemas funcionais sem justificativa técnica.
- Identificar claramente assets temporários como placeholders.
- Nunca adicionar credenciais, tokens ou arquivos sensíveis ao Git.
- Não fazer alterações destrutivas sem aprovação do diretor do projeto.

## Fluxo de trabalho

- Diretor do projeto: usuário.
- Arquitetura, planejamento e revisão: ChatGPT.
- Implementação e execução técnica: Codex.

O Codex pode propor melhorias. Mudanças importantes de arquitetura, gameplay,
narrativa ou direção artística precisam de aprovação do diretor do projeto antes
da implementação.

## Escopo e verificação das tarefas

- Cada tarefa deve ser pequena, verificável e identificada como ECHOES-XXX.
- Não implementar funcionalidades fora do escopo da tarefa atual.
- Antes de concluir, verificar erros, referências quebradas e arquivos modificados.
- Informar claramente quais arquivos foram criados ou alterados e o resultado das verificações.
