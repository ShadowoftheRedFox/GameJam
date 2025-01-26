from random import randint, seed
from time import time
from math import pi, cos, sin


class colors:
    HEADER = "\033[95m"
    OKBLUE = "\033[94m"
    OKCYAN = "\033[96m"
    OKGREEN = "\033[92m"
    WARNING = "\033[93m"
    FAIL = "\033[91m"
    ENDC = "\033[0m"
    BOLD = "\033[1m"
    UNDERLINE = "\033[4m"


def pmap(map: list[list[int]], selected: list[int]):
    for row in map:
        for x in row:
            if x in selected:
                print(f"{colors.WARNING}{"{:02d}".format(x)}{colors.ENDC}", end=", ")
            else:
                print("{:02d}".format(x), end=", ")
        print()


size = 10
nb = 12

map = []
selected = []
i = 0
for y in range(size):
    map.append([])
    for x in range(size):
        map[y].append(i)
        i += 1


def work_position(map, nb):
    for i in range(nb):
        # i to pos -> (i%size,i/size)
        u = i % 4
        r = 0
        d = int(i / 4)

        if u == 0:
            r = 0 + d
        if u == 1:
            r = size - 1 + d * size
        if u == 2:
            r = (size) * (size - 1) - d * size
        if u == 3:
            r = size * size - 1 - d

        x = r % size
        y = int(r / size)
        selected.append(map[y][x])


print("Répartition: ")
work_position(map, nb)
pmap(map, selected)

selected = []
print()
seed(time())


def work_position_rand(map, nb):
    if nb <= 0:
        return
    x = randint(0, size - 1)
    y = randint(0, size - 1)
    if map[y][x] in selected:
        work_position_rand(map, nb)
    else:
        selected.append(map[y][x])
        work_position_rand(map, nb - 1)


print("Random: ")
work_position_rand(map, nb)
pmap(map, selected)

selected = []
print()


def work_position_matrix(map, nb):
    base_x = randint(0, size - 1)
    base_y = randint(0, size - 1)
    angle = (2 * pi) / nb

    for i in range(nb):
        x = int(base_x * cos(angle * i) - base_y * sin(angle * i))
        y = int(base_x * sin(angle * i) + base_y * cos(angle * i))

        if x < 0 or x >= size:
            x = x % size
        if y < 0 or y >= size:
            y = y % size

        if map[y][x] in selected:
            i -= 1
        else:
            selected.append(map[y][x])


print("Matrice: ")
work_position_matrix(map, nb)
pmap(map, selected)
