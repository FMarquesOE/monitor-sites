#!/usr/bin/env bash
# Confere cada endereço de sites.txt. Abre um aviso (issue) quando cai e fecha quando volta.
set -uo pipefail
export TZ=America/Sao_Paulo
LABEL="fora-do-ar"
agora() { date '+%d/%m/%Y %H:%M'; }
mudou=0

gh label create "$LABEL" --color B60205 --description "Endereço fora do ar" --force >/dev/null 2>&1 || true

confere() { # $1 url, $2 texto esperado → imprime código; retorna 0 se ok
  local url="$1" esperado="$2" tentativa codigo corpo
  for tentativa in 1 2 3; do
    corpo=$(curl -sS -L -m 20 -A "monitor-fmarquestbg" -w $'\n%{http_code}' "$url" 2>/dev/null) || corpo=$'\n000'
    codigo="${corpo##*$'\n'}"
    corpo="${corpo%$'\n'*}"
    if [ "$codigo" = "200" ] && { [ -z "$esperado" ] || grep -qF -- "$esperado" <<<"$corpo"; }; then
      echo "$codigo"; return 0
    fi
    [ "$tentativa" -lt 3 ] && sleep 20
  done
  echo "$codigo"; return 1
}

while IFS='|' read -r nome url esperado dica; do
  [ -z "${nome// }" ] && continue
  [[ "$nome" == \#* ]] && continue
  titulo="🔴 $nome fora do ar"
  aberto=$(gh issue list --label "$LABEL" --state open --search "\"$titulo\" in:title" --json number,title \
    --jq ".[] | select(.title == \"$titulo\") | .number" | head -n1)

  if codigo=$(confere "$url" "$esperado"); then
    echo "OK    $nome ($codigo)"
    if [ -n "$aberto" ]; then
      gh issue comment "$aberto" --body "✅ Voltou ao ar em $(agora)." >/dev/null
      gh issue close "$aberto" >/dev/null
      echo "- $(agora) · ✅ $nome voltou ao ar" >> historico.md; mudou=1
    fi
  else
    [ "$codigo" = "200" ] && motivo="abriu, mas sem o texto esperado ($esperado)" || motivo="código $codigo (000 = não respondeu)"
    echo "FORA  $nome ($motivo)"
    if [ -z "$aberto" ]; then
      gh issue create --title "$titulo" --label "$LABEL" --body "$(printf '**Endereço:** %s\n**Desde:** %s (3 tentativas seguidas, com 20 s entre elas)\n**Resposta:** %s\n\n**O que conferir primeiro:** %s\n\nEste aviso fecha sozinho quando o endereço voltar.' "$url" "$(agora)" "$motivo" "$dica")" >/dev/null
      echo "- $(agora) · 🔴 $nome fora do ar ($motivo)" >> historico.md; mudou=1
    fi
  fi
done < sites.txt

# O GitHub desliga agendamentos de repositório parado há 60 dias: um registro a cada 45 dias mantém o monitor vivo.
ultimo=$(git log -1 --format=%ct 2>/dev/null || echo 0)
if [ $(( $(date +%s) - ultimo )) -gt $(( 45 * 86400 )) ]; then
  date '+%d/%m/%Y %H:%M' > .vivo; mudou=1
fi

if [ "$mudou" = 1 ]; then
  git config user.name "monitor"; git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
  git add -A && git commit -qm "Monitor: registro de $(agora)" && git push -q || true
fi
