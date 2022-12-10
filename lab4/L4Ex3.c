#include <avr/io.h>

int led_out;
int user_input;
int previous_state;

int main(void)
{
	DDRC = 0x00;				//Initialize PORTC as input
	DDRA = 0xFF;				//Initialize PORTA as output
	previous_state = 0x00;		//Initialize previous state
	led_out = 0x80;				//Initialize led output
	while (1)
	{
		int PORTA = led_out;
		user_input = PINC & 0x1F;
		if ((previous_state & 0x10) - (user_input & 0x10) == 16)		//Reset at starting position
		{
			led_out = 0x80;
		}
		else if ((previous_state & 0x08) - (user_input & 0x08) == 8)	//Shift left 2 places
		{
			if (led_out == 0x80)
				led_out = 0x02;
			else if (led_out == 0x40)
				led_out = 0x01;
			else
				led_out <<= 2;
		}
		else if ((previous_state & 0x04) - (user_input & 0x04) == 4)	//Shift right 2 places
		{
			if (led_out == 0x02)
				led_out = 0x80;
			else if (led_out == 0x01)
				led_out = 0x40;
			else
				led_out >>= 2;
		}
		else if ((previous_state & 0x02) - (user_input & 0x02) == 2)	//Shift left 1 place
		{
			if (led_out == 0x80)
				led_out = 0x01;
			else
				led_out <<= 1;
		}
		else if ((previous_state & 0x01) - (user_input & 0x01) == 1)	//Shift right 1 place
		{
			if (led_out == 0x01)
				led_out = 0x80;
			else
				led_out >>= 1;
		}
		previous_state = user_input;								//Store previous state
	}
	return 0;
}
