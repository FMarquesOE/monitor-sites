# Monitor dos sites · Felipe Marques Consultoria

Confere a cada 10 minutos se estes endereços estão no ar:

| Endereço | O que é |
|---|---|
| www.fmarquestbg.com.br | Site da consultoria |
| vmafraunhas.com.br | Site do studio |
| fmarquestbg-ig-autopilot.vercel.app | Automação do Instagram (pela página de privacidade, que é pública) |
| t.fmarquestbg.com.br | FM Connect: placas e cartões (pela conferência `/api/health`, que testa também o banco) |

## Como funciona
- Cada endereço tem 3 tentativas, com 20 s entre elas, antes de ser dado como fora (para não avisar por um soluço da rede).
- **Caiu:** abre um aviso em **Issues**, com o rótulo `fora-do-ar`, e o GitHub manda email para a conta dona do repositório.
- **Voltou:** comenta o horário e fecha o aviso sozinho.
- Cada queda e cada volta ficam em `historico.md`.
- Para conferir na hora: aba **Actions** → "Monitor dos sites" → **Run workflow**.

## Para mudar
- Incluir ou tirar um endereço: editar `sites.txt` (uma linha por endereço).
- Repositório público de propósito: assim o GitHub Actions não cobra minutos. Só aparecem endereços que já são públicos; nenhuma senha fica aqui.
