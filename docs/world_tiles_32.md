# ECHOES-012 — Floresta provisória em tiles 32×32

- Engine oficial: Godot 4.7.2. Usar `TileMapLayer`, sem `TileMap` legado.
- Cena: `res://scenes/world/TestWorld.tscn`.
- TileSet compartilhado: `res://resources/tilesets/world_tileset.tres`.
- Grade quadrada: 32×32 px, com origem local em `(0, 0)`.
- O mapa de 2560×1440 corresponde a 80×45 células:
  colunas 0–79 e linhas 0–44. Isso descreve a área; não impõe limites.

## Camadas do mapa

As três `TileMapLayer` estão sob `TestWorld/Tiles` e usam o mesmo TileSet:

| Camada | Uso | Z relativo | Colisões |
| --- | --- | --- | --- |
| Terrain | Solo e caminho, preenchendo toda a área | 0 | Desabilitadas |
| Vegetation | Grama decorativa nas margens e clareiras | 1 | Desabilitadas |
| Obstacles | Vegetação densa, árvores e pedras | 2 | Habilitadas |

O TileSet usa a camada de física existente com layer/mask 1, compatível com
o Player. Somente vegetação densa, árvores e pedras possuem polígonos sólidos.
A borda de vegetação densa tem duas células de espessura e fecha o mapa.
Navegação permanece desabilitada; não há pathfinding ou IA.

## Atlas técnico placeholder

`res://assets/sprites/placeholders/forest_tiles_placeholder.svg` é um atlas
de 192×32 px, com seis regiões de 32×32, na fonte 0 do TileSet:

| Coordenada do atlas | Representação provisória | Colisão |
| --- | --- | --- |
| (0, 0) | Solo escuro | Não |
| (1, 0) | Terra/caminho | Não |
| (2, 0) | Grama decorativa | Não |
| (3, 0) | Vegetação densa | Quadrado 32×32 |
| (4, 0) | Árvore | Retângulo 22×28 |
| (5, 0) | Pedra | Retângulo 24×22 |

São formas técnicas simples, sem arte final. O Player permanece com seu
placeholder de 32×48 px, colisão e velocidade originais.

O filtro `Nearest` é herdado de `Tiles` para os futuros tiles de pixel art.
As configurações globais de exibição e o renderer GL Compatibility não mudam.
Essa filtragem não estabelece escalonamento inteiro ou pixel perfect global.

## Percurso de teste

Coordenadas abaixo são células, não pixels. O Player inicia no centro da
célula (10, 35), em `(336, 1136)` px, numa clareira caminhável.

- Caminho principal: (10,35) → (22,35) → (22,27) → (40,27) → (40,22)
  → (53,22) → (53,14) → (68,14) → (68,8).
- Ramificações: (22,27) → (12,27) → (12,16);
  (40,22) → (40,9); (53,22) → (64,22) → (64,33).
- Clareiras: (10,35), (12,16), (40,9), (64,33) e (68,8).
- A clareira (68,8) reserva espaço para o futuro acesso ao abrigo.
  Não há construção, transição de cena ou gatilho implementado.
- Caminhos têm cinco tiles de terra e margens caminháveis, com espaço para
  o Player de 32×48. Árvores e pedras isoladas permitem testar desvio.

## Transição e limites desta etapa

Os polígonos da ECHOES-010 estão preservados nos mesmos nós, ocultos por
`visible = false` nos cinco grupos originais. Os tiles são agora o cenário
visível e jogável. O mapa é salvo na cena, sem geração durante a execução.
As camadas continuam atrás do Player pelo Z do TestWorld; ordenação por
profundidade de personagens e obstáculos fica para uma tarefa futura.
Não foram adicionados limites de câmera nem sistemas além do mapa e colisões.
