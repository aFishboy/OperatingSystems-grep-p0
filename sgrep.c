#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdbool.h>
//test
#define COLOR_CODE	"\e[0;31m" /* Red */
#define RESET_CODE	"\e[0;0m"

struct node {
   char* data;
   struct node *next;
};
typedef struct node node_t;

node_t* head = NULL;
node_t* tail = NULL;

void listAppend(char string[]){
	node_t* newNode = malloc(sizeof(node_t));
	newNode->data = string;
	newNode->next = NULL;
	if (head == NULL){
		head = newNode;
		tail = newNode;
	}
	else{
		tail->next = newNode;
		tail = newNode;
	}
}

void deallocate(node_t* head){
	node_t* currentNode;
	while (head != NULL){
		currentNode = head;
		head = head->next;
		free(currentNode);
		//printf("deallocated\n");
	}

}

void printList(){
	node_t* holder = head;

	while (holder != NULL){
		printf("%s - ", holder->data);
		holder = holder->next;
	}
	printf("\n\n");
}

char* getNextLine(FILE* filep);
char* getNextWord(char* currLine);
bool isPatternWord(char* currWord);
void printCurrentWord(bool color, char* currWord);
bool patternInLine(char* currLine);


int main(int argc, char* argv[]){	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	const char USAGE[] = "Usage: ./sgrep [-n] [-c] [-h] [-p PATTERN]... FILE..."; 

	if (argc < 2){
		printf("%s\n", USAGE);
		return 1;
	}

	bool printLineNum, coloring = 0;

	char* arg;
	for (int i = 1; i < argc; i++){
		arg = argv[i];
		if (!(strcmp(arg, "-n"))){
			printLineNum = true;
			//printf("was -n %i \n", printLineNum);
		}
		else if (!(strcmp(arg, "-c"))){
			coloring = true;
			//printf("was -c %i \n", coloring);
		}
		else if (!(strcmp(arg, "-h"))){
			//printf("%s\n", USAGE);
		}
		else if (!(strcmp(arg, "-p"))){
			//printf("was -p\n");
			listAppend(argv[++i]);
		}
		else{ // none of the parameters so must be file or non valid input
			//fopen the current argv
			while (i < argc){
				FILE* fp = fopen(argv[i], "r");
				if (fp == NULL){
					printf("\nfopen: No such file or directory\n\n");
					return 1;
				}
				else{
					char* currentLine;
					char* currentWord = NULL;
					int lineNum = 0;
					while (!feof(fp)){
						
						currentLine = getNextLine(fp);
						lineNum++;
				
						char copyString[1025];
						strcpy(copyString, currentLine);

						if (patternInLine(currentLine)){
							if (printLineNum){
								printf("%i: ", lineNum);
							}
							currentWord = getNextWord(copyString);

							if (currentWord != NULL){
								printCurrentWord(coloring, currentWord);
							}
							
							while (currentWord != NULL){
								currentWord = getNextWord(NULL);
								if (currentWord != NULL){
									printCurrentWord(coloring, currentWord);
								}
							}
						}
								
					}
				}
				//printf("Current Arg: %i\n", i);
				i++;
			}
			break;
		}
		
	}

	deallocate(head);
	return 0;
}


char* getNextLine(FILE* filep){
	char currLine[1024];
	//printf("\n strrrrrrrr: %s\n", currLine);

	fgets(currLine, 1024, filep);
	char* str = currLine;

	return str;
}

char* getNextWord(char* copyString){
	char* currWord = strtok(copyString, " ");
	return currWord;
}

bool isPatternWord(char* currWord){
	node_t* tempNode = head;
	while (tempNode != NULL){
		if (!(strcmp(tempNode->data, currWord))){
			return true;
		}
		//printf("\n%s\n", tempNode->next->data);

		tempNode = tempNode->next;
	}
	return false;
}

void printCurrentWord(bool color, char* currWord){
	if (isPatternWord(currWord) && color){
		if (currWord[strlen(currWord)-1] == '\n'){
			printf(COLOR_CODE "%s" RESET_CODE, currWord);
		}
		else{
			printf(COLOR_CODE "%s " RESET_CODE, currWord);
		}
	}
	else{
		if (currWord[strlen(currWord)-1] == '\n'){
			printf("%s", currWord);
		}
		else{
			printf("%s ", currWord);
		}
	}
	return;
}

bool patternInLine(char* currLine){
	node_t* tempNode = head;
	while (tempNode != NULL){
		if (strstr(currLine, tempNode->data) != NULL){
			return true;
		}
		tempNode = tempNode->next;
	}
	return false;
}


