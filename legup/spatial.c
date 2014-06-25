#include <stdio.h>

#define N 16

volatile int sortData[N] = {4, 7, 5, 3, 8, 1, 0, 9, 4, 10, 2, 5, 7, 2, 3, 0};
volatile int sortedData[N];

// spatial sorter
int main() {
	int i, j;
	int buff[N];
	
	j = 0;
	
	for (i = 0; i < N; i++)
		buff[i] = 0;
	
	printf("Start\n");
	
	for (i = 0; i < N; i++) {
		int new = sortData[i];
		int tmp;
		for (j = 0; j < i; j++) {
			if (new < buff[j]) {
				tmp = buff[j];
				buff[j] = new;
				new = tmp;
			}
		}
		buff[i] = new;
	}
	
	for (i = 0; i < N; i++)
		sortedData[i] = buff[i];

	printf("End\n");
	
	return 0;
}

