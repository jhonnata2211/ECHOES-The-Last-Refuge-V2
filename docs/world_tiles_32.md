# ECHOES-011 — Base do mundo em tiles 32×32

- Engine oficial: Godot 4.7.2. Usar `TileMapLayer`, sem `TileMap` legado.
- Cena: `res://scenes/world/TestWorld.tscn`.
- TileSet compartilhado: `res://resources/tilesets/world_tileset.tres`.
- Grade quadrada: 32×32 px, com origem local em `(0, 0)`.
- O chão provisório de 2560×1440 corresponde a 80×45 células:
  colunas 0–79 e linhas 0–44. Isso descreve a área; não impõe limites.

## Camadas preparadas

As três `TileMapLayer` estão sob `TestWorld/Tiles` e usam o mesmo TileSet:

| Camada | Uso futuro | Z relativo | Colisões |
| --- | --- | --- | --- |
| Terrain | Chão e terreno | 0 | Desabilitadas |
| Vegetation | Vegetação decorativa | 1 | Desabilitadas |
| Obstacles | Obstáculos sólidos | 2 | Habilitadas, sem formas ainda |

O TileSet reserva uma camada de física com layer/mask 1, compatível com
a configuração atual do Player. Ainda não existem fontes, células pintadas
ou polígonos de colisão: o mundo continua sem colisões. Navegação permanece
desabilitada nas três camadas.

O filtro `Nearest` é herdado de `Tiles` para os futuros tiles de pixel art.
As configurações globais de exibição e o renderer GL Compatibility não mudam.
Essa filtragem não estabelece escalonamento inteiro ou pixel perfect global.

## Transição posterior

Os polígonos atuais são placeholders preservados e continuam visíveis.
Em tarefas aprovadas posteriormente, adicionar fontes de atlas de tiles
32×32 ao TileSet, pintar as camadas e definir colisões dos obstáculos.
Substituir os placeholders somente quando os tiles estiverem validados.
As camadas continuam atrás do Player pelo Z do TestWorld; ordenação por
profundidade de personagens e obstáculos fica para uma tarefa futura.
