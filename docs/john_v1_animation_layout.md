# ECHOES-014 / ECHOES-014A / ECHOES-014D — Integração visual do John V1

## Estado desta etapa

O PNG técnico original do John V1 foi integrado a partir do ZIP fornecido,
sem alteração, redimensionamento ou redesenho. A concept sheet continua
sendo referência e não é usada diretamente como textura no jogo.

`Player.tscn` exibe AnimatedSprite2D com filtro Nearest, escala padrão e
centro local `(0, 0)`. O Sprite2D azul de 32×48 permanece na cena, oculto,
como fallback. `resources/player/john_v1_frames.tres` contém as oito
animações e 28 AtlasTexture, vinculados ao mesmo PNG por referência externa,
com as regiões 32×48 preparadas na ECHOES-014A. As marcações `asset_pending`
da cena e do recurso foram desativadas.

PNG integrado: 192×384, RGBA com transparência, 85.242 bytes.
SHA-256: `1331ed6e21065cc0146c29af5f1ffd5351c96bc56cea7d7535eb057d3746c409`.
As 28 células usadas têm conteúdo; as outras 20 células de idle são transparentes.

Na entrada da cena, `player.gd` procura o PNG no caminho definitivo e conecta
o atlas aos frames somente se sua dimensão for exatamente 192×384. Não
redimensiona, estica ou recorta a referência visual. Se o PNG faltar, retorna
sem tentar carregá-lo; se tiver dimensão incorreta, emite um aviso.

Depois verifica se todas as oito animações possuem frames com texturas e
atlas válidos de 192×384. Se a validação dos frames falhar, ativa o placeholder
azul e o AnimatedSprite2D oculto. Ainda assim seleciona o estado/direção para
permitir verificar a lógica. Com o conjunto completo, passa a exibir e tocar
o AnimatedSprite2D. A aparência permanece a do asset fornecido e aprovado.

## Layout do asset integrado

PNG RGBA com fundo transparente, sem rótulos, grade desenhada, margens ou
espaçamento entre células. Caminho definitivo do asset:
`assets/sprites/player/john_v1.png`.

- Imagem: **192×384 px**.
- Células: **32×48 px**.
- Grade: **6 colunas × 8 linhas**, contando a partir de zero.
- Cada direção deve ser desenhada separadamente; não espelhar laterais.
- Manter proporções, cabelo, óculos, roupa e mochila do concept aprovado.
- Manter o mesmo alinhamento do corpo e dos pés entre os frames, sem recortar
  cada frame por seu conteúdo. O centro da célula é `(16, 24)`.

| Linha | Y em pixels | Animação | Colunas usadas | FPS inicial |
| --- | --- | --- | --- | --- |
| 0 | 0–47 | idle_down (frente) | 0 | 1 |
| 1 | 48–95 | idle_up (costas) | 0 | 1 |
| 2 | 96–143 | idle_left | 0 | 1 |
| 3 | 144–191 | idle_right | 0 | 1 |
| 4 | 192–239 | walk_down | 0–5 | 10 |
| 5 | 240–287 | walk_up | 0–5 | 10 |
| 6 | 288–335 | walk_left | 0–5 | 10 |
| 7 | 336–383 | walk_right | 0–5 | 10 |

Nas linhas de idle, deixar as colunas 1–5 transparentes e não adicioná-las à
animação. Os seis frames de cada caminhada devem formar um ciclo em loop,
na ordem da esquerda para a direita. Um idle estático já atende esta etapa.

O SpriteFrames já mapeia cada AtlasTexture com região
`Rect2(coluna * 32, linha * 48, 32, 48)`, margem zero, `filter_clip = true`
e duração relativa 1 por frame. Os frames walk usam X = 0, 32, 64, 96, 128,
160 nessa ordem; cada idle usa X = 0. Não há espelhamento de direção.

O PNG participa da importação normal do Godot. A referência externa no
SpriteFrames permite visualizar os frames no editor e registra a dependência
do asset para exportação. O carregamento visual continua validando o atlas
em memória; não regrava recursos nem arquivos do projeto durante a execução.
Nomes, loops, FPS, regiões e durações da ECHOES-014A foram preservados.

A concept sheet continua sendo somente referência: nem mesmo uma imagem de
192×384 deve ser considerada produção sem possuir o layout aprovado de
frames. Esta etapa copia somente o PNG original, sem criar arte substituta.

## Regra de animação

- Movimento continua usando Input.get_vector e move_and_slide, a 200 px/s.
- A direção visual usa o vetor de entrada: se `abs(x) > abs(y)`, escolhe
  esquerda/direita; caso contrário, cima/baixo. Empates priorizam vertical.
- Sem nova direção de entrada, preserva a última orientação (inicial: down).
- Walk depende do deslocamento real informado por get_real_velocity após
  move_and_slide. Parado, inclusive bloqueado por um obstáculo, usa idle.
- Não existem animações diagonais. A movimentação física continua em oito
  direções e com velocidade diagonal normalizada.
- CollisionShape2D e Camera2D continuam independentes do tamanho visual;
  não ajustar a colisão automaticamente ao importar sprites.
