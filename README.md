# limpeza-usuario

Script de limpeza focado **só no perfil do usuário logado**. Sem admin, sem mexer em pasta de sistema, sem tocar na lixeira.

Desenvolvido por **Davi Senise — Técnico de Suporte TI**.

---

## escopo (e por que ele é assim)

Este script limpa **somente** o que vive dentro do perfil do usuário:

| # | O que limpa | Onde |
|---|---|---|
| 1 | Temporários do usuário | `%TEMP%` |
| 2 | Cache de internet | `%LOCALAPPDATA%\Microsoft\Windows\INetCache` |
| 3 | Crash dumps | `%LOCALAPPDATA%\CrashDumps` |
| 4 | Cache de miniaturas | `thumbcache_*.db` do Explorer |
| 5 | Cache de navegadores | Chrome e Edge — **só a pasta Cache** |

O que ele **não** toca, de propósito:

- **Lixeira** — em máquina com OneDrive corporativo, a lixeira que o usuário vê pode ser a da nuvem, que nenhum script local esvazia. Pra não gerar relatório enganoso ("esvaziada" sem esvaziar), ficou fora do escopo.
- **Pastas de sistema** (`C:\Windows\Temp`, Prefetch, cache de update) — exigem admin e pertencem a outro tipo de manutenção. Tem script pra isso no [windows-sysadmin-toolkit](https://github.com/davisenise/windows-sysadmin-toolkit).
- **Senhas, histórico, cookies e favoritos de navegador** — jamais. Só cache.

> Escopo pequeno e bem definido > escopo grande cheio de ressalva.

---

## o diferencial: relatório honesto

A maioria dos scripts de limpeza usa `Remove-Item pasta\* -Recurse` e engole erro. Quando bate em arquivo em uso (e em máquina ligada sempre tem), falha em cascata, pula um monte de coisa **e não te conta**.

Aqui é diferente:

- **Loop item a item** com `try/catch` por arquivo — o que está em uso é pulado, o resto é removido.
- **Conta os dois**: removidos *e* pulados. O relatório mostra "120 removidos, 45 em uso (pulados)" em vez de fingir que estava tudo limpo.
- **Avisa antes** se Chrome/Edge estão abertos — porque navegador aberto trava o próprio cache.

---

## como usar

1. Baixe `limpeza-usuario.bat` e `limpeza-usuario.ps1` na mesma pasta
2. Dê dois cliques no `.bat` (não precisa de administrador)
3. Confirme com `S`

O relatório sai em `%USERPROFILE%\limpeza_usuario_DATA.txt`.

> Dica: feche os navegadores antes de rodar pra limpeza pegar o cache deles por completo.

---

## requisitos

- Windows 10 ou 11
- PowerShell 5.1 ou superior
- Nenhuma permissão especial

---

## outros repositórios

| Repositório | O que é |
|---|---|
| [windows-sysadmin-toolkit](https://github.com/davisenise/windows-sysadmin-toolkit) | Guias, checklists e inventário de hardware pra suporte Windows |
| [inventario-ti](https://github.com/davisenise/inventario-ti) | Inventário de máquinas em rede com export pra Excel |

---

## autor

**Davi Senise** — Técnico de Suporte TI
[LinkedIn](https://www.linkedin.com/in/davisenise/) · [GitHub](https://github.com/davisenise)
