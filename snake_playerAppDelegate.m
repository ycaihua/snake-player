//
//  snake_playerAppDelegate.m
//  snake-player
//
//  Created by John Altenmueller on 12/27/10.
//

#import "snake_playerAppDelegate.h"
#include <stdio.h>
#include <unistd.h>
#include <math.h>

@implementation snake_playerAppDelegate

@synthesize window;

#define block_width		8
#define block_height	8
#define grid_width		64
#define grid_height		32
#define total_width		512
#define total_height	256

// keyboard codes
const CGKeyCode LEFT = 123;
const CGKeyCode RIGHT = 124;
const CGKeyCode DOWN = 125;
const CGKeyCode UP = 126;

const int origin_x = 43 + 2;
const int origin_y = 98 + 2;

// 61166 is color.red for empty space
// 65535 is color.red for food
// 21845 is color.red for snake

typedef struct
{
	bool grid[grid_width][grid_height];
	NSPoint head;
	NSPoint food;
	NSPoint dest;
	bool dest_valid;
	CGKeyCode dir;
	bool avoiding;
	CGKeyCode avoid_dir;
	int state;
} Snake;

Snake get_snake();
NSPoint find_head(const Snake* old_snake, const Snake* new_snake);
bool path_clear_x(const Snake* snake, int x1, int x2, int y);
bool path_clear_y(const Snake* snake, int y1, int y2, int x);
char* dir_string(int dir);
void nspoint_print(NSPoint point);

Snake update_snake(Snake* snake)
{
	Snake	new_snake = get_snake();
	NSPoint new_head = find_head(snake, &new_snake);
	new_snake.head.x = new_head.x;
	new_snake.head.y = new_head.y;
	new_snake.dir = snake->dir;
	new_snake.dest = snake->dest;
	new_snake.dest_valid = snake->dest_valid;
	new_snake.state = snake->state;
	return new_snake;
}

Snake get_snake()
{
	Snake snake;
	RGBColor color;
		
	memset( snake.grid, 0, sizeof (snake.grid));
		
	for (int i=0; i<grid_height; i++)
	{
		for (int j=0; j<grid_width; j++)
		{
			GetCPixel(origin_x + j*block_width, origin_y + i*block_height, &color);
			if (color.red == 65535)
			{
				snake.food.x = j;
				snake.food.y = grid_height-i-1;
			}
			else if (color.red == 21845)
			{
				snake.grid[j][grid_height-i-1] = TRUE;
			}
		}
	}
	return snake;
}

void print_snake(Snake* snake)
{
	for (int i=0; i<32; i++)
	{
		for (int j=0; j<64; j++)
		{
			if (snake->grid[j][i])
				printf("*");
			else
				printf(" ");
		}
		puts("");
	}
}

NSPoint find_head(const Snake* old_snake, const Snake* new_snake)
{
	for (int i=0; i<grid_height; i++)
		for (int j=0; j<grid_width; j++)
		{
			if ( new_snake->grid[j][i] && !old_snake->grid[j][i] )
			{
				NSPoint head;
				head.x = j;
				head.y = i;
				return head;
			}
		}
	return old_snake->head;
}

int min(int a, int b)
{
	if (a < b) return a;
	else return b;
}

int max(int a, int b)
{
	if (a > b) return a;
	else return b;
}

bool path_clear_x(const Snake* snake, int x1, int x2, int y)
{
	int start = min(x1, x2);
	int end = max(x1, x2);
	
	if ( (start<0) || (end>=grid_width) ||
			 (y<0) || (y>=grid_height))
	{
		return false;
	}
	
	for (int i=start; i<=end; i++)
	{
		if (snake->grid[i][y])
		{
			return false;
		}
	}
	return true;
}

bool path_clear_y(const Snake* snake, int y1, int y2, int x)
{
	int start = min(y1, y2);
	int end = max(y1, y2);
	
	if ( (start<0) || (end>=grid_height) ||
			 (x<0) || (x>=grid_width))
	{
		return false;
	}
	
	for (int i=start; i<=end; i++)
	{
		if (snake->grid[x][i])
		{
			return false;
		}
	}
	return true;
}

/*NSPoint* findHead()
{
	NSPoint *head = FALSE;
	RGBColor color;
	for (int i=0; i<total_height; i+=block_height)
	{
		for (int j=0; j<total_width; j+=block_width)
		{
			GetCPixel(origin_x + j, origin_y + i, &color);
			if ( color.red == 21845 )
			{
				head = malloc(sizeof (NSPoint));
				head->x = i/block_width;
				head->y = j/block_height;
				return head;
			}
		}
	}
	return head;
}*/

int get_dir(Snake* snake)
{
	if (snake->dest.x-snake->head.x > 0)
		snake->dir=RIGHT;
	else if (snake->dest.x-snake->head.x < 0)
		snake->dir=LEFT;
	else if (snake->dest.y-snake->head.y > 0)
		snake->dir=UP;
	else
		snake->dir=DOWN;
	return snake->dir;
}

NSPoint get_next_pos(Snake* snake, CGKeyCode dir)
{
	NSPoint pos;
	if (dir == UP)
	{
		pos.x = snake->head.x;
		pos.y = snake->head.y+1;
	}
	else if (dir == DOWN)
	{
		pos.x = snake->head.x;
		pos.y = snake->head.y-1;
	}
	else if (dir == RIGHT)
	{
		pos.x = snake->head.x+1;
		pos.y = snake->head.y;
	}
	else
	{
		pos.x = snake->head.x-1;
		pos.y = snake->head.y;
	}
	return pos;
}

int get_total_count(Snake* snake)
{
	int count = 0;
	for (int i=0; i<grid_width; i++)
	{
		for (int j=0; j<grid_height; j++)
		{
			if (snake->grid[i][j])
			{
				count++;
			}
		}
	}
	return count;
}

void wrappable_area(Snake* snake, NSPoint* p1, NSPoint* p2)
{
	if ( (snake->dir == UP) || (snake->dir == DOWN) )
	{
		int x1 = snake->head.x-1;
		int y1 = snake->head.y;
		int y2 = snake->dest.y;
		while(path_clear_y(snake, y1, y2, x1))
		{
			x1--;
		}
		x1++;
		
		int x2 = snake->head.x+1;
		while(path_clear_y(snake, y1, y2, x2))
		{
			x2++;
		}
		x2--;
		
		p1->x = min(x1, x2);
		p1->y = min(y1, y2);
		p2->x = max(x1, x2);
		p2->y = max(y1, y2);
	}
}

int count_clear_spaces(Snake* snake, CGKeyCode dir)
{
	int count = 0;
	if (dir == UP)
	{
		for (int i=snake->head.y+1; i<grid_height; i++)
		{
			if (snake->grid[(int)snake->head.x][i])
				break;
			else
				count++;
		}
	}
	else if (dir == DOWN)
	{
		for (int i=snake->head.y-1; i>=0; i--)
		{
			if (snake->grid[(int)snake->head.x][i])
				break;
			else
				count++;
		}
	}
	else if (dir == RIGHT)
	{
		for (int i=snake->head.x+1; i<grid_width; i++)
		{
			if (snake->grid[i][(int)snake->head.y])
				break;
			else
				count++;
		}
	}
	else if (dir == LEFT)
	{
		for (int i=snake->head.x-1; i>=0; i--)
		{
			if (snake->grid[i][(int)snake->head.y])
				break;
			else
				count++;
		}
	}
	
	return count;
}

// count the number of clear spaces in a 5x5 block around the point
int count_clear_spaces_square(Snake* snake, NSPoint point)
{
	int count=0;
	int i_start, i_max;
	int j_start, j_max;
	
	if (point.x-2 < 0)
		i_start = 0;
	else
		i_start = point.x-2;
	
	if (point.x+3 >= grid_width)
		i_max = grid_width;
	else
		i_max = point.x+3;
	
	if (point.y-2 < 0)
		j_start = 0;
	else
		j_start = point.y-2;
	
	if (point.y+3 >= grid_height)
		j_max = grid_height;
	else
		j_max = point.y+3;
	
	for (int i=i_start; i<i_max; i++)
	{
		for (int j=j_start; j<j_max; j++)
		{
			if ( !snake->grid[i][j] )
			{
				count++;
			}
		}
	}
	return count;
}

bool right_clear(Snake* snake)
{
	int x = (int)snake->head.x+1;
	int y = (int)snake->head.y;
	if ((x < grid_width) && (!snake->grid[x][y]))
		return TRUE;
	else
	{
		printf("collision x:%d y:%d\n", x, y);
		puts("");
		return FALSE;
	}
}

bool left_clear(Snake* snake)
{
	int x = (int)snake->head.x-1;
	int y = (int)snake->head.y;
	if ((snake->head.x-1 >= 0) &&
			(!snake->grid[(int)snake->head.x-1][(int)snake->head.y]))
		return TRUE;
	else
	{
		printf("collision x:%d y:%d\n", x, y);
		puts("");
		return FALSE;
	}
}

bool up_clear(Snake* snake)
{
	int x = (int)snake->head.x;
	int y = (int)snake->head.y+1;
	if ((snake->head.y+1 < grid_height) &&
			(!snake->grid[(int)snake->head.x][(int)snake->head.y+1]))
		return TRUE;
	else
	{
		printf("collision x:%d y:%d\n", x, y);
		puts("");
		return FALSE;
	}
}

bool down_clear(Snake* snake)
{
	int x = (int)snake->head.x;
	int y = (int)snake->head.y-1;
	if ((snake->head.y-1 >= 0) &&
			(!snake->grid[(int)snake->head.x][(int)snake->head.y-1]))
		return TRUE;
	else
	{
		printf("collision x:%d y:%d\n", x, y);
		return FALSE;
	}
}

bool next_clear(Snake* snake)
{
	if (snake->dir == RIGHT)
	{
		int x = (int)snake->head.x+1;
		int y = (int)snake->head.y;
		if ((x < grid_width) && (!snake->grid[x][y]))
		{
			return TRUE;
		}
		else
		{
			return FALSE;
		}
	}
	else if (snake->dir == LEFT)
	{
		if ((snake->head.x-1 >= 0) &&
				(!snake->grid[(int)snake->head.x-1][(int)snake->head.y]))
		{
			return TRUE;
		}
		else
		{
			return FALSE;
		}
	}
	else if (snake->dir == UP)
	{
		if ((snake->head.y+1 < grid_height) &&
				(!snake->grid[(int)snake->head.x][(int)snake->head.y+1]))
		{
			return TRUE;
		}
		else
		{
			return FALSE;
		}
	}
	else
	{
		if ((snake->head.y-1 >= 0) &&
				(!snake->grid[(int)snake->head.x][(int)snake->head.y-1]))
		{
			return TRUE;
		}
		else
		{
			return FALSE;
		}
	}
}

void avoid_collision(Snake* snake, CGKeyCode old_dir)
{
//	NSPoint pos = get_next_pos(snake, snake->dir);
	if ( !next_clear(snake) )
	{
//		printf("pos.x: %d pos.y %d\n", (int)pos.x, (int)pos.y);
		snake->avoid_dir = snake->dir;
		snake->dir = old_dir;
		snake->avoiding = TRUE;
		snake->dest_valid = FALSE;
		
		if ( next_clear(snake) )
		{
			return;
		}
		else if ( (snake->dir == UP) || (snake->dir == DOWN) )
		{
			int right_clear = count_clear_spaces(snake, RIGHT);
			int left_clear = count_clear_spaces(snake, LEFT);
			printf("Right clear: %d, Left clear: %d\n", right_clear, left_clear);
			if ( (right_clear >= 2) && (left_clear >= 2) && (abs(right_clear-left_clear) < 5) )
			{
				puts("Determining with advanced avoidance algorithm... ******************");
				// determine with squares
				NSPoint left, right;
				int l_square_count, r_square_count;
				left.x = snake->head.x-3; right.y = snake->head.y;
				right.x = snake->head.x+3; right.y = snake->head.y;
				r_square_count = count_clear_spaces_square(snake, right);
				l_square_count = count_clear_spaces_square(snake, left);
				if (r_square_count > l_square_count)
				{
					snake->dir = RIGHT;
				}
				else
				{
					snake->dir = LEFT;
				}
			}
			else if ( right_clear > left_clear )
				snake->dir = RIGHT;
			else
				snake->dir = LEFT;
		}
		else
		{
			int up_clear = count_clear_spaces(snake, UP);
			int down_clear = count_clear_spaces(snake, DOWN);
			printf("Up clear: %d, Down clear, %d\n", up_clear, down_clear);
			if ( (up_clear >= 2) && (down_clear >= 2) && (abs(up_clear-down_clear) < 10) )
			{
				puts("Determining with advanced avoidance algorithm... ******************");
				// determine with squares
				NSPoint up, down;
				int u_square_count, d_square_count;
				up.x = snake->head.x; up.y = snake->head.y+3;
				down.x = snake->head.x; down.y = snake->head.y+3;
				u_square_count = count_clear_spaces_square(snake, up);
				d_square_count = count_clear_spaces_square(snake, down);
				if (u_square_count > d_square_count)
				{
					snake->dir = UP;
				}
				else
				{
					snake->dir = DOWN;
				}
			}			
			else if ( up_clear > down_clear )
				snake->dir = UP;
			else
				snake->dir = DOWN;
		}
	}
}

void travel(Snake* snake)
{
	int delta_x = snake->food.x - snake->head.x;
	int delta_y = snake->food.y - snake->head.y;
	snake->avoiding = FALSE;
		
	// determine if travelling towards food
	if (((delta_x > 0) && (snake->dir == RIGHT)) ||
			((delta_x < 0) && (snake->dir == LEFT)))
	{
		snake->dest.x = snake->food.x;
		snake->dest.y = snake->head.y;
	}
	else if (((delta_y > 0) && (snake->dir == UP)) ||
					 ((delta_y < 0) && (snake->dir == DOWN)))
	{
		snake->dest.x = snake->head.x;
		snake->dest.y = snake->food.y;
	}
	else if ((delta_x != 0) && (snake->dir == UP || snake->dir == DOWN))
	{
		snake->dest.x = snake->food.x;
		snake->dest.y = snake->head.y;
	}
	else if ((delta_y != 0) && (snake->dir == RIGHT || snake->dir == LEFT))
	{
		snake->dest.x = snake->head.x;
		snake->dest.y = snake->food.y;
	}
	// flip
	else if ( (snake->dir == UP) || (snake->dir == DOWN) )
	{
		snake->dest.x = snake->head.x+1;
		snake->dest.y = snake->head.y;
	}
	else
	{
		snake->dest.x = snake->head.x;
		snake->dest.y = snake->head.y+1;
	}
	
	snake->dest_valid = TRUE;
//	snake->dir=get_dir(snake);
	
	printf("head "); nspoint_print(snake->head);
	printf("food "); nspoint_print(snake->food);
	printf("delta_x: %.0f delta_y: %.0f\n",
				 snake->dest.x-snake->head.x, snake->dest.y-snake->head.y);
	if (snake->dest.x-snake->head.x > 0)
		snake->dir=RIGHT;
	else if (snake->dest.x-snake->head.x < 0)
		snake->dir=LEFT;
	else if (snake->dest.y-snake->head.y > 0)
		snake->dir=UP;
	else
		snake->dir=DOWN;
}

bool nspoint_eq(NSPoint p1, NSPoint p2)
{
	if ( (p1.x == p2.x) && (p1.y == p2.y) )
		return true;
	else return false;
}

void nspoint_print(NSPoint point)
{
	printf("x: %.0f y: %.0f\n", point.x, point.y);
}

char* dir_string(int dir)
{
	if (dir == UP)
		return "UP";
	else if (dir == DOWN)
		return "DOWN";
	else if (dir == RIGHT)
		return "RIGHT";
	else return "LEFT";
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
		
	int k = 5;
	while (k > 0)
	{
		k--;
		sleep(1);
		printf("%d ", k);
	}
	puts("");
//	Snake mysnake = get_snake();
//  print_snake(&mysnake);
	
	Snake old_snake;
	memset(old_snake.grid, 0, sizeof(bool[grid_width][grid_height]));
	
	
	CGKeyCode old_dir;
	NSPoint newPoint;
	Snake snake = get_snake();
	newPoint = find_head(&old_snake, &snake);
	snake.head.x = newPoint.x;
	snake.head.y = newPoint.y;
	snake.dir=UP;
	printf("head x = %f, y = %f\n", newPoint.x, newPoint.y);
	puts(dir_string(snake.dir));
	
  while (1)
	{
		Snake new_snake = update_snake(&snake);
//		printf("%2d x = %f, y = %f\n", i, new_snake.head.x, new_snake.head.y);
		
		// check if we need to stop avoiding
/*		if (new_snake.avoiding)
		{
			NSPoint pos = get_next_pos(&snake, snake.avoid_dir);
			if (!new_snake.grid[(int)pos.x][(int)pos.y])
			{
				new_snake.avoiding=FALSE;
				travel(&new_snake);
			}
		}*/
		// figure out if we need a new destination
		/*else*/
		
		int x_old = snake.head.x;
		int y_old = snake.head.y;
		int x = new_snake.head.x;
		int y = new_snake.head.y;
		
		if ( (x != x_old) || (y != y_old) )
		{
			old_dir = new_snake.dir;
			if ( ( nspoint_eq(new_snake.head, new_snake.dest) && new_snake.dest_valid) ||
					!new_snake.dest_valid )
			{
				travel(&new_snake);
			}
			avoid_collision(&new_snake, old_dir);
			
			if (new_snake.dir != snake.dir)
			{
				CGEventRef e = CGEventCreateKeyboardEvent (NULL, new_snake.dir, true);
				CGEventPost(kCGSessionEventTap, e);
				CFRelease(e);
				puts(dir_string(new_snake.dir));
			}
			
			snake = new_snake;
		}
		usleep(5000);
	}
	puts("Finished");
	// Insert code here to initialize your application 
}

@end
