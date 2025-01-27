from typing import Self, List, Dict, Tuple
import random

## Pièce individuelle
class Room:
    num: int = 0
    def __init__(self: Self):
        self.id:         int  = self.num    # ID interne
        self.con_left:   Self | None = None # Connexions
        self.con_right:  Self | None = None
        self.con_up:     Self | None = None
        self.con_down:   Self | None = None
        Room.num += 1

    def __repr__(self: Self) -> str:
        return (f"  {' ' if self.con_up == None else '|'}  \n"
                f"{' ' if self.con_left == None else '-'}{self.id:03}{' ' if self.con_right == None else '-'}\n"
                f"  {' ' if self.con_down == None else '|'}  ")

## Une zone est un ensemble de pièces
class Area:
    num: int = 0
    def __init__(self: Self, area_height: int, area_width: int):
        self.rooms: List[List[Room]] = [[Room() for _ in range(area_width)] for _ in range(area_height)]
        self.id = Area.num
        Area.num += 1
        self.height = area_height
        self.width = area_width

    # Génération des pièces.
    # Pour l'instant, ne fait que la liaison.
    # Note: chance = chance d'une connexion (labyrinthe non-parfait)
    def randomize(self: Self, chance: float):
        # Implémentation rapide d'un DFS
        def dfs(x, y):
            directions = [(0, 1), (1, 0), (0, -1), (-1, 0)]
            random.shuffle(directions)
            for dx, dy in directions:
                nx, ny = x + dx, y + dy
                if 0 <= nx < self.height and 0 <= ny < self.width and not visited[ny][nx]:
                    if dx == 0 and dy == 1:
                        self.rooms[y][x].con_down = self.rooms[ny][nx]
                        self.rooms[ny][nx].con_up = self.rooms[y][x]
                    elif dx == 1 and dy == 0:
                        self.rooms[y][x].con_right = self.rooms[ny][nx]
                        self.rooms[ny][nx].con_left = self.rooms[y][x]
                    elif dx == 0 and dy == -1:
                        self.rooms[y][x].con_up = self.rooms[ny][nx]
                        self.rooms[ny][nx].con_down = self.rooms[y][x]
                    elif dx == -1 and dy == 0:
                        self.rooms[y][x].con_left = self.rooms[ny][nx]
                        self.rooms[ny][nx].con_right = self.rooms[y][x]
                    
                    visited[ny][nx] = True
                    dfs(nx, ny)

        visited = [[False] * self.width for _ in range(self.height)]
        start_x, start_y = random.randint(0, self.width - 1), random.randint(0, self.height - 1)
        visited[start_y][start_x] = True
        dfs(start_x, start_y)
        
        # Ajout des connexions en plus
        for y in range(self.height):
            for x in range(self.width):
                if random.random() < chance:
                    directions = []
                    if y > 0 and not self.rooms[y][x].con_up:
                        directions.append((0, -1))
                    if y < self.height - 1 and not self.rooms[y][x].con_down:
                        directions.append((0, 1))
                    if x > 0 and not self.rooms[y][x].con_left:
                        directions.append((-1, 0))
                    if x < self.width - 1 and not self.rooms[y][x].con_right:
                        directions.append((1, 0))
                    
                    if directions:
                        dx, dy = random.choice(directions)
                        nx, ny = x + dx, y + dy
                        if dx == 0 and dy == 1:
                            self.rooms[y][x].con_down = self.rooms[ny][nx]
                            self.rooms[ny][nx].con_up = self.rooms[y][x]
                        elif dx == 1 and dy == 0:
                            self.rooms[y][x].con_right = self.rooms[ny][nx]
                            self.rooms[ny][nx].con_left = self.rooms[y][x]
                        elif dx == 0 and dy == -1:
                            self.rooms[y][x].con_up = self.rooms[ny][nx]
                            self.rooms[ny][nx].con_down = self.rooms[y][x]
                        elif dx == -1 and dy == 0:
                            self.rooms[y][x].con_left = self.rooms[ny][nx]
                            self.rooms[ny][nx].con_right = self.rooms[y][x]

    def __repr__(self: Self) -> str:
        repr_str = ""
        for row in self.rooms:
            top_row = ""
            mid_row = ""
            bottom_row = ""
            for room in row:
                top_row += f"  {' ' if room.con_up == None else '|'}  "
                mid_row += f"{' ' if room.con_left == None else '-'}{room.id:03}{' ' if room.con_right == None else '-'}"
                bottom_row += f"  {' ' if room.con_down == None else '|'}  "
            repr_str += top_row + "\n" + mid_row + "\n" + bottom_row + "\n"
        return repr_str


# Classe pour le monde. Note: Classe INTERMEDIARE!!!
class World:
    num: int = 0
    
    # Classe pour un connecteur
    class Connector:
        num: int = 0
        def __init__(self):
            self.id: int = World.Connector.num
            World.Connector.num += 1
            self.room: Room = Room()

        def display(self):
            print(f"Connector ID: {self.id}\nAssociated Room:")
            print(self.room)

    def __init__(self, world_height: int, world_width: int, area_height: int, area_width: int, chance: float):
        self.id: int = World.num
        World.num += 1
        self.areas: List[List[Area]] = [[Area(area_height, area_width) for _ in range(world_width)] for _ in range(world_height)]
        self.connectors: Dict[Tuple[int, int], Dict[Tuple[int, int], 'World.Connector']] = {}
        # On connecte les zones entre elles
        for i in range(world_height):
            for j in range(world_width):
                if i > 0:
                    self.connect_areas(i, j, i-1, j)
                if j > 0:
                    self.connect_areas(i, j, i, j-1)
                self.areas[i][j].randomize(chance)

    def connect_areas(self, y1: int, x1: int, y2: int, x2: int):
        if (y1, x1) not in self.connectors:
            self.connectors[(y1, x1)] = {}
        if (y2, x2) not in self.connectors:
            self.connectors[(y2, x2)] = {}
        connector = World.Connector()

        self.connectors[(y1, x1)][(y2, x2)] = connector
        self.connectors[(y2, x2)][(y1, x1)] = connector

        # On place un connecteur sur le milieu d'un coté d'une zone
        mid_x1 = len(self.areas[y1][x1].rooms[0]) // 2
        mid_y1 = len(self.areas[y1][x1].rooms) // 2
        mid_x2 = len(self.areas[y2][x2].rooms[0]) // 2
        mid_y2 = len(self.areas[y2][x2].rooms) // 2

        # TODO: Permettre les connexions non-alignés tant qu'elles sont de meme sens
        if x1 == x2:
            if y1 < y2:
                self.areas[y1][x1].rooms[-1][mid_x1].con_down = connector.room
                connector.room.con_up = self.areas[y1][x1].rooms[-1][mid_x1]
                self.areas[y2][x2].rooms[0][mid_x2].con_up = connector.room
                connector.room.con_down = self.areas[y2][x2].rooms[0][mid_x2]
            else:
                self.areas[y1][x1].rooms[0][mid_x1].con_up = connector.room
                connector.room.con_down = self.areas[y1][x1].rooms[0][mid_x1]
                self.areas[y2][x2].rooms[-1][mid_x2].con_down = connector.room
                connector.room.con_up = self.areas[y2][x2].rooms[-1][mid_x2]
        elif y1 == y2:
            if x1 < x2:
                self.areas[y1][x1].rooms[mid_y1][-1].con_right = connector.room
                connector.room.con_left = self.areas[y1][x1].rooms[mid_y1][-1]
                self.areas[y2][x2].rooms[mid_y2][0].con_left = connector.room
                connector.room.con_right = self.areas[y2][x2].rooms[mid_y2][0]
            else:  # x1 is to the right of x2
                self.areas[y1][x1].rooms[mid_y1][0].con_left = connector.room
                connector.room.con_right = self.areas[y1][x1].rooms[mid_y1][0]
                self.areas[y2][x2].rooms[mid_y2][-1].con_right = connector.room
                connector.room.con_left = self.areas[y2][x2].rooms[mid_y2][-1]
        else:
            raise ValueError("Pas encore implémenté déso frr")

# Classe du monde FINAL. Le monde final est une carte qui contient un tableau applatit de toutes les salles.
# Les zones sont séparés d'une distance de 2 pour permettre aux connecteurs d'être placés
class FinalWorld:
    def __init__(self, world: World):
        self.area_height = len(world.areas[0][0].rooms)
        self.area_width = len(world.areas[0][0].rooms[0])
        self.height = len(world.areas) * (self.area_height + 2)
        self.width = len(world.areas[0]) * (self.area_width + 2)
        self.map: List[Room|None] = [None for _ in range(self.height * self.width)]

        self.flatten_world(world)

    def flatten_world(self, world: World):
        for area_y in range(len(world.areas)):
            for area_x in range(len(world.areas[area_y])):
                area = world.areas[area_y][area_x]
                base_y = area_y * (self.area_height + 2)
                base_x = area_x * (self.area_width + 2)

                # On place d'abord les salles
                for y in range(self.area_height):
                    for x in range(self.area_width):
                        self.map[(base_y + y + 1) * self.width + (base_x + x + 1)] = area.rooms[y][x]

                # Puis les connecteurs
                if (area_y, area_x) in world.connectors:
                    for (area_y2, area_x2), connector in world.connectors[(area_y, area_x)].items():
                        mid_x1 = self.area_width // 2
                        mid_y1 = self.area_height // 2

                        # Torvalds à dit: "Si t'as besoin de plus de troix niveau d'indentation,
                        # t'as mal fait quelque chose.
                        # On est à 7 ici. Oops.
                        if area_y2 == area_y and area_x2 == area_x + 1:
                            self.map[(base_y + mid_y1 + 1) * self.width + (base_x + self.area_width + 1)] = connector.room
                        elif area_y2 == area_y and area_x2 == area_x - 1:
                            self.map[(base_y + mid_y1 + 1) * self.width + (base_x)] = connector.room
                        elif area_y2 == area_y + 1 and area_x2 == area_x:
                            self.map[(base_y + self.area_height + 1) * self.width + (base_x + mid_x1 + 1)] = connector.room
                        elif area_y2 == area_y - 1 and area_x2 == area_x:
                            self.map[(base_y) * self.width + (base_x + mid_x1 + 1)] = connector.room
    
    # Note: On affiche les connexions des connecteurs mal, mais flemme, c'est du debug.
    def display(self):
        for y in range(self.height):
            top_row = ""
            mid_row = ""
            bottom_row = ""
            for x in range(self.width):
                room = self.map[y * self.width + x]
                if room:
                    top_row += f"  {' ' if room.con_up is None else '|'}  "
                    mid_row += f"{' ' if room.con_left is None else '-'}{room.id:03}{' ' if room.con_right is None else '-'}"
                    bottom_row += f"  {' ' if room.con_down is None else '|'}  "
                else:
                    top_row += "     "
                    mid_row += "     "
                    bottom_row += "     "
            print(top_row)
            print(mid_row)
            print(bottom_row)

def main():
    world = World(3, 3, 5, 5, 0)
    final_world = FinalWorld(world)
    final_world.display()
main()
