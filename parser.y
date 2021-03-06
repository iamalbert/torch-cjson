
%{
    #include <cstdio>
    #include <string>
    #include <memory>

    #include "JsonNode.h"
    #include "parser.hpp"
    #include "token.h"

    extern int yylex(YYSTYPE * yylval, yyscan_t  scanner, JsonState * state );
    extern void yyerror(yyscan_t scanner, JsonState*, const char *);

%}

%define parse.error verbose
%pure-parser
%lex-param {void * scanner} 
%parse-param {void * scanner} 
%param {JsonState * state}
/*

%lex-param {void *scanner}
%parse-param {void *scanner}
*/

%union {
    JsonValue * value;
    const char* strval;
    double numval;
}

%{
%}

%token <numval> T_NUMBER 
%token <strval> T_STRING

%token T_LEFT_CUR T_RIGHT_CUR T_LEFT_BRAK T_RIGHT_BRAK
%token T_TRUE T_FALSE T_NULL
%token T_COMMA T_COLON
%token T_END_OF_FILE
%token T_UNKNOWN
    
%type <value>  array object
%type <strval> string
%type <value>  members elements element 

%start start

%%

start: element { state->value = $1; }

array: T_LEFT_BRAK elements T_RIGHT_BRAK { 
        $$ = $2;
    }| T_LEFT_BRAK T_RIGHT_BRAK { 
        $$ = state->newObject<JsonArray>();
    }
;
elements: element {
        //printf("ele %c\n", $1->type );
        $$ = state->newObject<JsonArray>();
        $$->as<JsonArray>()->ptrVec.push_back($1);

    }| elements T_COMMA element {
        //printf("eles(%c) ele(%c)\n", $1->type, $3->type);
        $1->as<JsonArray>()->ptrVec.push_back($3);
        $$ = $1;
    }
;
object: T_LEFT_CUR members T_RIGHT_CUR { 
        //puts("obj");
        $$ = $2;
    }| T_LEFT_CUR T_RIGHT_CUR {
	    $$ = state->newObject<JsonObject>();
    }
;
members: string T_COLON element  {
        $$ = state->newObject<JsonObject>();

        $$->as<JsonObject>()->ptrTable[($1)] = $3 ;

        //delete (std::string*) $1;
        //printf("mem(%s:%c)\n", $1->as<JsonPair>()->key->c_str(), $1->member->type);
    }|   members T_COMMA string T_COLON element {
        $1->as<JsonObject>()->ptrTable[($3)] = $5;
        //delete (std::string*) $1;
        $$ = $1;
    }
;
string : T_STRING {
    $$ = $1 ; //state->getString($1);
}
element: string {
        $$ = state->newObject<JsonString>($1);
    }| T_NUMBER {
        $$ = state->newObject<JsonNumber>($1);
    }| T_TRUE {
        $$ = state->newObject<JsonBoolean>(true);
    }| T_FALSE {
        $$ = state->newObject<JsonBoolean>(false);
    }| T_NULL {
        $$ = state->newObject<JsonNull>();
    }| array {
        $$ = $1;
    }| object {
        $$ = $1;
    }
;

%%

//extern int yylex(YYSTYPE*);

void yyerror(yyscan_t scanner, JsonState *state, const char * err ) {
	char msg[BUFSIZ];
	snprintf(msg, BUFSIZ, "Line: %d, Token: %s, Error: %s", 
		yyget_lineno(scanner), yyget_text(scanner), err );
    puts(msg);
    state->free();
	//throw std::runtime_error(msg);
}

bool parse_json( FILE * fp, JsonState * state ){
    yyscan_t scanner;

    yylex_init(&scanner);
    yyset_in( fp, scanner );
    yyparse(scanner, state);
    yylex_destroy(scanner);

    return state->value != nullptr;
}
bool parse_json_string( const char * string, JsonState *state ){
    yyscan_t scanner;
    yylex_init(&scanner);
    YY_BUFFER_STATE buffer = yy_scan_string(string, scanner);
    yyset_lineno(1, scanner);
    yyparse(scanner, state);
    yy_delete_buffer(buffer, scanner);
    yylex_destroy(scanner);

    return state->value != nullptr;
}

