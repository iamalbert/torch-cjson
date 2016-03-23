#ifndef JSON_NODE_H
#define JSON_NODE_H

extern "C" {
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
}

#define LS lua_State *L

#include <vector>
#include <string>
#include <iostream>
#include <exception>
#include <stdexcept>
#include <deque>

#include <cassert>

struct JsonValue {
    JsonValue *next;
    JsonValue *member;
    JsonValue();

    virtual ~JsonValue();

    virtual void breakLinks();
    virtual std::ostream &print(std::ostream &os) const;
    virtual std::ostream &printJson(std::ostream &os) const;
    virtual int toLuaObject(LS);
    int asLuaObject(LS);
    JsonValue *reverse_member();
};

struct JsonString;

struct JsonPair : public JsonValue {
    std::string *key;
    JsonPair(std::string *k);

    virtual ~JsonPair();
    virtual std::ostream &print(std::ostream &os) const;
    virtual std::ostream &printJson(std::ostream &os) const;

    virtual int toLuaObject(LS);
};

struct JsonObject : public JsonValue {
    virtual std::ostream &print(std::ostream &os) const;
    virtual std::ostream &printJson(std::ostream &os) const;
    virtual int toLuaObject(LS);
};

struct JsonArray : public JsonValue {
    virtual std::ostream &print(std::ostream &os) const;
    virtual std::ostream &printJson(std::ostream &os) const;
    virtual int toLuaObject(LS);
};

struct JsonString : public JsonValue {
    std::string *value;
    JsonString(std::string *s);
    ~JsonString();

    virtual std::ostream &print(std::ostream &os) const;
    virtual std::ostream &printJson(std::ostream &os) const;
    virtual int toLuaObject(LS);
};
struct JsonNumber : public JsonValue {
    double value;
    JsonNumber(double v);
    virtual std::ostream &print(std::ostream &os) const;
    virtual std::ostream &printJson(std::ostream &os) const;
    virtual int toLuaObject(LS);
};
struct JsonBoolean : public JsonValue {
    bool value;
    JsonBoolean(bool b);
    virtual std::ostream &print(std::ostream &os) const;
    virtual std::ostream &printJson(std::ostream &os) const;
    virtual int toLuaObject(LS);
};
struct JsonNull : public JsonValue {
    virtual std::ostream &print(std::ostream &os) const;
    virtual std::ostream &printJson(std::ostream &os) const;
    virtual int toLuaObject(LS);
};

struct JsonState {
    JsonValue *value;
    std::deque<JsonValue *> objList;

    JsonState();

    template <class T, class... Args> T *newObject(Args &&... args) {
        static_assert(std::is_base_of<JsonValue, T>::value,
                      "must derived from JsonValue");
        T *obj = new T(std::forward<Args>(args)...);
        objList.push_back(obj);
        return obj;
    }

    JsonValue *getJsonValue() const;

    void free();
};

struct JsonException : public std::runtime_error {
    template <class... Args>
    JsonException(Args &&... args)
        : std::runtime_error(std::forward<Args>(args)...) {}
};

JsonValue *parse_json(FILE *);

#endif
