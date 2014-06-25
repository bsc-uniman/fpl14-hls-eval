#include <stdio.h>

typedef struct {
	unsigned short valid;
	unsigned short key;
	unsigned int data;
} hash_entry;

volatile hash_entry ht[HLEN];

typedef struct {
	unsigned short key;
	unsigned int data;
} row_t;

volatile row_t table[TLEN];

typedef struct {
	unsigned int t1;
	unsigned int t2;
} result;

volatile result outData[TLEN];

inline unsigned short hash(unsigned short v) {
	unsigned short h = v;
	for (unsigned int i = 0; i < 16; i++) {
		char v10 = (h >> 10) & 0x1;
		char v12 = (h >> 12) & 0x1;
		char v13 = (h >> 13) & 0x1;
		char v15 = (h >> 15) & 0x1;
		h = (h << 1) | ((((v15 ^ v13) ^ v12) ^ v10) & 0x1);
	}
	return h;
}

// hash probe
int main() {
	int i;
	int j;
	int outptr;
	
	printf("Start\n");
	outptr = 0;
	for (i = 0; i < TLEN; i++) {
		unsigned int key = table[i].key;
		unsigned int index = hash(key) % HLEN;
		while (ht[index].valid) {
			if (ht[index].key == key) {
				result r = {ht[index].data, table[i].data};
				outData[outptr++] = r;
				break;
			}
			index = (index + 1) % HLEN;
		}
	}
	
	printf("Finish\n");
	
	return outptr;
}

