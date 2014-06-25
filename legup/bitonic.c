#include <stdio.h>

#define N 16
volatile int inData[N] = {4, 7, 5, 3, 8, 1, 0, 9, 4, 10, 2, 5, 7, 2, 3, 0};
volatile int outData[N];

#define CAS(v, i, j) do { int _t; \
	if ((v)[(i)] > (v)[(j)]) { \
		_t = (v)[(i)]; \
		(v)[(i)] = (v)[(j)]; \
		(v)[(j)] = _t; \
	} \
	} while(0)

int main() {
	int i, j, k, l;
	int sortData[N];

	printf("Start\n");
	
	for (i = 0; i < N; i++)
		sortData[i] = inData[i];
	
	printf("Start sorting\n");
	
	// stage 0
	CAS(sortData, 0, 1);
	CAS(sortData, 2, 3);
	CAS(sortData, 4, 5);
	CAS(sortData, 6, 7);
	CAS(sortData, 8, 9);
	CAS(sortData, 10, 11);
	CAS(sortData, 12, 13);
	CAS(sortData, 14, 15);
	
	// stage 1
	CAS(sortData, 0, 3);
	CAS(sortData, 4, 7);
	CAS(sortData, 8, 11);
	CAS(sortData, 12, 15);
	CAS(sortData, 1, 2);
	CAS(sortData, 5, 6);
	CAS(sortData, 9, 10);
	CAS(sortData, 13, 14);

	// stage 2
	CAS(sortData, 0, 1);
	CAS(sortData, 2, 3);
	CAS(sortData, 4, 5);
	CAS(sortData, 6, 7);
	CAS(sortData, 8, 9);
	CAS(sortData, 10, 11);
	CAS(sortData, 12, 13);
	CAS(sortData, 14, 15);

	// stage 3
	CAS(sortData, 0, 7);
	CAS(sortData, 1, 6);
	CAS(sortData, 2, 5);
	CAS(sortData, 3, 4);
	CAS(sortData, 8, 15);
	CAS(sortData, 9, 14);
	CAS(sortData, 10, 13);
	CAS(sortData, 11, 12);

	// stage 4
	CAS(sortData, 0, 2);
	CAS(sortData, 1, 3);
	CAS(sortData, 4, 6);
	CAS(sortData, 5, 7);
	CAS(sortData, 8, 10);
	CAS(sortData, 9, 11);
	CAS(sortData, 12, 14);
	CAS(sortData, 13, 15);

	// stage 5
	CAS(sortData, 0, 1);
	CAS(sortData, 2, 3);
	CAS(sortData, 4, 5);
	CAS(sortData, 6, 7);
	CAS(sortData, 8, 9);
	CAS(sortData, 10, 11);
	CAS(sortData, 12, 13);
	CAS(sortData, 14, 15);

	// stage 6
	CAS(sortData, 0, 15);
	CAS(sortData, 1, 14);
	CAS(sortData, 2, 13);
	CAS(sortData, 3, 12);
	CAS(sortData, 4, 11);
	CAS(sortData, 5, 10);
	CAS(sortData, 6, 9);
	CAS(sortData, 7, 8);
	
	// stage 7
	CAS(sortData, 0, 4);
	CAS(sortData, 1, 5);
	CAS(sortData, 2, 6);
	CAS(sortData, 3, 7);
	CAS(sortData, 8, 12);
	CAS(sortData, 9, 13);
	CAS(sortData, 10, 14);
	CAS(sortData, 11, 15);

	// stage 8
	CAS(sortData, 0, 2);
	CAS(sortData, 1, 3);
	CAS(sortData, 4, 6);
	CAS(sortData, 5, 7);
	CAS(sortData, 8, 10);
	CAS(sortData, 9, 11);
	CAS(sortData, 12, 14);
	CAS(sortData, 13, 15);

	// stage 9
	CAS(sortData, 0, 1);
	CAS(sortData, 2, 3);
	CAS(sortData, 4, 5);
	CAS(sortData, 6, 7);
	CAS(sortData, 8, 9);
	CAS(sortData, 10, 11);
	CAS(sortData, 12, 13);
	CAS(sortData, 14, 15);

	printf("Finished sorting\n");

	for (i = 0; i < N; i++)
		outData[i] = sortData[i];

	printf("Finish\n");

	return 0;
}

