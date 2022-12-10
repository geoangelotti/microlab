#include <avr/io.h>

int main(void) {
	int input;
	int A, B, C, D, E;
	int F0, F1, F2;
	DDRA = 0x00;				//set port A for input
	DDRC = 0xff;				//set port C for output
	while (1) {
		//read input and store it
		input = PINA;
		A = input & 0x01;		//A is the 1st LSB
		B = input & 0x02;		//B is the 2nd LSB
		B = B >> 1;				//1 logical shift right
		C = input & 0x04;		//C is the 3rd LSB
		C = C >> 2;				//2 logical shifts right
		D = input & 0x08;		//D is the 4th LSB
		D = D >> 3;				//3 logical shifts right
		E = input & 0x10;		//E is the 5th LSB
		E = E >> 4;				//4 logical shifts right
		//calculate the functions
		F0 = !((A & B & C) | (C & D) | (D & E));
		F1 = ((A & B & C) | (!D & !E));
		F2 = (F1 | F0);
		F0 = F0 << 5;			//F0 is the 5th LSB, 5 logical shifts left
		F1 = F1 << 6;			//F1 is the 6th LSB, 6 logical shifts left
		F2 = F2 << 7;			//F2 is the 7th LSB, 7 logical shifts left
		//set output
		PORTC = F2 | F1 | F0;
	}
}
