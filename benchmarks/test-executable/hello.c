#include <stdio.h>

int main(int argc, char*argv[]) {
    char *outstr = "default hi!";
    if (argc > 1) {
        outstr = argv[1];
    }
    printf("Hello world: %s \n", outstr);
    return 0;
}
