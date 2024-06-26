/*
 * group member(s):
 *      Ronan Kelley
 */
%{
#define WIDTH 640
#define HEIGHT 480

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <SDL2/SDL.h>
#include <SDL2/SDL_thread.h>

static SDL_Window* window;
static SDL_Renderer* rend;
static SDL_Texture* texture;
static SDL_Thread* background_id;
static SDL_Event event;
static int running = 1;
static const int PEN_EVENT = SDL_USEREVENT + 1;
static const int DRAW_EVENT = SDL_USEREVENT + 2;
static const int COLOR_EVENT = SDL_USEREVENT + 3;

typedef struct color_t {
    unsigned char r;
    unsigned char g;
    unsigned char b;
} color;

static color current_color;
static double x = WIDTH / 2;
static double y = HEIGHT / 2;
static int pen_state = 1;
static double direction = 0.0;
static double variables[26];

int yylex(void);
int yyerror(const char* s);
void startup();
int run(void* data);
void prompt();
void penup();
void pendown();
void move(int num);
void turn(int dir);
void turt_goto(int new_x, int new_y);
void output(const char* s);
void change_color(int r, int g, int b);
void clear();
void save(const char* path);
void shutdown();
double getVarValue(const char* var);

%}

%union {
    float f;
    char* s;
}

%locations

%token SEP
%token PENUP
%token PENDOWN
%token PRINT
%token CHANGE_COLOR
%token COLOR
%token CLEAR
%token TURN
%token MOVE
%token NUMBER
%token END
%token SAVE
%token PLUS SUB MULT DIV
// -- begin student added tokens -- //
%token GOTO
%token WHERE
%token<s> VARIABLE
%token EQUAL
// -- end student added tokens -- //
%token<s> STRING QSTRING
%type<f> expression expression_list NUMBER

%%

program:        statement_list END                              { printf("Program complete."); shutdown(); exit(0); }
        ;
statement_list: statement
        |       statement statement_list
        ;
statement:      command SEP                                     { prompt(); }
        |       error '\n'                                      { yyerrok; prompt(); }
        ;
command:        PENUP                                           { penup(); }
        |       PENDOWN                                         { pendown(); }
        |       PRINT STRING                                    { printf("%s\n", yylval.s); }
        |       PRINT expression                                { printf("%f\n", $2); }
        |       PRINT VARIABLE                                  { printf("%s = %f\n", $2, getVarValue($2)); }
        |       SAVE STRING                                     { save(yylval.s); }
        |       CLEAR                                           { clear(); }
        |       WHERE                                           { printf("(x, y): (%.2f, %.2f)\n", x, y); }
        |       TURN expression                                 { turn((int) $2); }
        |       TURN VARIABLE                                   { turn((int) getVarValue($2)); }
        |       MOVE expression                                 { move((int) $2); }
        |       MOVE VARIABLE                                   { move((int) getVarValue($2)); }
        |       CHANGE_COLOR expression expression expression   { change_color((int) $2,(int) $3,(int) $4); }
        |       CHANGE_COLOR VARIABLE VARIABLE VARIABLE         { change_color((int) getVarValue($2), (int) getVarValue($3), (int) getVarValue($4)); }
        |       GOTO expression expression                      { turt_goto((int) $2, (int) $3); }
        |       GOTO VARIABLE VARIABLE                          { turt_goto((int) getVarValue($2), (int) getVarValue($3)); }
        |       VARIABLE EQUAL expression                       { variables[$1[0] - 'A'] = $3; }
        ;
expression_list:expression
        |       expression expression_list
        ;
expression:     NUMBER PLUS expression                          { $$ = $1 + $3; }
        |       NUMBER MULT expression                          { $$ = $1 * $3; }
        |       NUMBER SUB expression                           { $$ = $1 - $3; }
        |       NUMBER DIV expression                           { $$ = $1 / $3; }
        |       NUMBER
        ;

%%

int main(int argc, char** argv){
    startup();
    // yyparse();
    return 0;
}

int yyerror(const char* s){
    printf("Error: %s\n", s);
    return -1;
};

void prompt(){
    printf("gv_logo > ");
}

void penup(){
    event.type = PEN_EVENT;        
    event.user.code = 0;
    SDL_PushEvent(&event);
}

void pendown() {
    event.type = PEN_EVENT;        
    event.user.code = 1;
    SDL_PushEvent(&event);
}

void move(int num){
    event.type = DRAW_EVENT;
    event.user.code = 1;
    event.user.data1 = num;
    SDL_PushEvent(&event);
}

void turn(int dir){
    event.type = PEN_EVENT;
    event.user.code = 2;
    event.user.data1 = dir;
    SDL_PushEvent(&event);
}

// not named goto because that's a reserved keyword in C
void turt_goto(int new_x, int new_y)
{
    event.type = DRAW_EVENT;
    event.user.code = 3;
    event.user.data1 = new_x;
    event.user.data2 = new_y;
    SDL_PushEvent(&event);
}

double getVarValue(const char* var)
{
    // you best believe I am not doing any safety checks
    // just write perfect code every time
    return variables[var[0] - 'A'];
}

void output(const char* s){
    printf("%s\n", s);
}

void change_color(int r, int g, int b){
    r = r % 255;
    g = g % 255;
    b = b % 255;
    event.type = COLOR_EVENT;
    current_color.r = r;
    current_color.g = g;
    current_color.b = b;
    SDL_PushEvent(&event);
}

void clear(){
    event.type = DRAW_EVENT;
    event.user.code = 2;
    SDL_PushEvent(&event);
}

void startup(){
    SDL_Init(SDL_INIT_VIDEO);
    window = SDL_CreateWindow("GV-Logo", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, WIDTH, HEIGHT, SDL_WINDOW_SHOWN);
    if (window == NULL){
        yyerror("Can't create SDL window.\n");
    }
    
    //rend = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_TARGETTEXTURE);
    rend = SDL_CreateRenderer(window, -1, SDL_RENDERER_SOFTWARE | SDL_RENDERER_TARGETTEXTURE);
    SDL_SetRenderDrawBlendMode(rend, SDL_BLENDMODE_BLEND);
    texture = SDL_CreateTexture(rend, SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_TARGET, WIDTH, HEIGHT);
    if(texture == NULL){
        printf("Texture NULL.\n");
        exit(1);
    }
    SDL_SetRenderTarget(rend, texture);
    SDL_RenderSetScale(rend, 3.0, 3.0);

    background_id = SDL_CreateThread(run, "Parser thread", (void*)NULL);
    if(background_id == NULL){
        yyerror("Can't create thread.");
    }
    while(running){
        SDL_Event e;
        while( SDL_PollEvent(&e) ){
            if(e.type == SDL_QUIT){
                running = 0;
            }
            if(e.type == PEN_EVENT){
                if(e.user.code == 2){
                    double degrees = ((int)e.user.data1) * M_PI / 180.0;
                    direction += degrees;
                // else added by student to fix the "turn" command effectively
                // also calling "pendown" at the same time
                } else {
                    pen_state = e.user.code;
                }
            }
            if(e.type == DRAW_EVENT){
                if(e.user.code == 1){
                    int num = (int)event.user.data1;
                    double x2 = x + num * cos(direction);
                    double y2 = y + num * sin(direction);
                    if(pen_state != 0){
                        SDL_SetRenderTarget(rend, texture);
                        SDL_RenderDrawLine(rend, x, y, x2, y2);
                        SDL_SetRenderTarget(rend, NULL);
                        SDL_RenderCopy(rend, texture, NULL, NULL);
                    }
                    x = x2;
                    y = y2;
                } else if(e.user.code == 2){
                    SDL_SetRenderTarget(rend, texture);
                    SDL_RenderClear(rend);
                    SDL_SetTextureColorMod(texture, current_color.r, current_color.g, current_color.b);
                    SDL_SetRenderTarget(rend, NULL);
                    SDL_RenderClear(rend);
                } else if (e.user.code == 3){
                    // STUDENT ADDED EVENT BAYBEE! I don't feel like sending a chain of
                    // turn/move events to accomplish the goto implementation so we're
                    // doin' it right here as its own event. Would it make more sense if it
                    // was event number 2? Yes. Am I going to change every call to event 2
                    // to a 3 (I'm pretty sure it's just the clear function but still)? No,
                    // it doesn't seem like it.
                    //
                    // on an unrelated note, my neovim setup is not real sure what to do with
                    // bison files like this one. I'm pretty sure treesitter can handle syntax
                    // highlighting 2 languages within one file like this - it does for markdown,
                    // at least - but I don't know enough about configuring it to do that myself.
                    // a deep dive for another day, I suppose.

                    // this should really just be a struct that stores an X and a Y but in my
                    // defense this *is* slightly faster to implement
                    int x2 = (int)event.user.data1;
                    int y2 = (int)event.user.data2;

                    if(pen_state != 0){
                        SDL_SetRenderTarget(rend, texture);
                        SDL_RenderDrawLine(rend, x, y, x2, y2);
                        SDL_SetRenderTarget(rend, NULL);
                        SDL_RenderCopy(rend, texture, NULL, NULL);
                    }
                    x = x2;
                    y = y2;
                }
            }
            if(e.type == COLOR_EVENT){
                SDL_SetRenderTarget(rend, NULL);
                SDL_SetRenderDrawColor(rend, current_color.r, current_color.g, current_color.b, 255);
            }
            if(e.type == SDL_KEYDOWN){
            }

        }
        //SDL_RenderClear(rend);
        SDL_RenderPresent(rend);
        SDL_Delay(1000 / 60);
    }
}

int run(void* data){
    prompt();
    yyparse();
}

void shutdown(){
    running = 0;
    SDL_WaitThread(background_id, NULL);
    SDL_DestroyWindow(window);
    SDL_Quit();
}

void save(const char* path){
    SDL_Surface *surface = SDL_CreateRGBSurface(0, WIDTH, HEIGHT, 32, 0, 0, 0, 0);
    SDL_RenderReadPixels(rend, NULL, SDL_PIXELFORMAT_ARGB8888, surface->pixels, surface->pitch);
    SDL_SaveBMP(surface, path);
    SDL_FreeSurface(surface);
}
