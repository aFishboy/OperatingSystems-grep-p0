#include <stdio.h>
#include <string.h>

#define COLOR_CODE	"\e[0;31m" /* Red */
#define RESET_CODE	"\e[0;0m"

int main(void)
{
	char *str = "I love ECS150!";
	char *love = "love";

	printf("%.*s", 2, str);
	printf(COLOR_CODE "%s" RESET_CODE, love);
	printf("%s\n", strstr(str, love) + strlen(love));

	return 0;
}
