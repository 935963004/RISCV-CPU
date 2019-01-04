#include "io.h"
int main()
{
	int a[15];
	for(int i = 0; i < 15; ++i){
		a[i] = i;
		outl(a[i]);
	}
    return 0;
}
