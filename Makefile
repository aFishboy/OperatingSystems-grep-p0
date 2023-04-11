all: example sgrep

example: example.c
	gcc -Wall -Wextra -Werror -o example example.c
sgrep: sgrep.c
	gcc -Wall -Wextra -Werror -o sgrep sgrep.c

clean:
	rm -f example
