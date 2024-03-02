#define LIB_NAME "LuaScriptInstance"
#define MODULE_NAME "lua_script_instance"

#include <dmsdk/sdk.h>

static int Get_impl(lua_State* L)
{
    DM_LUA_STACK_CHECK(L, 1);
    dmScript::GetInstance(L);
    if (!dmScript::IsInstanceValid(L))
    {
       lua_pop(L,-1);
       dmLogError("Script instance is not set");
       return DM_LUA_ERROR("Script instance is not set");
    }
    return 1;
}

static int Set_impl(lua_State* L)
{
    DM_LUA_STACK_CHECK(L, -1);
    if (!dmScript::IsInstanceValid(L))
    {
        dmLogError("Instance is not valid")
        return DM_LUA_ERROR("Instance is not valid");
    }
    dmScript::SetInstance(L);
    return 0;
}

// Functions exposed to Lua
static const luaL_reg Module_methods[] =
{
    {"Get", Get_impl},
    {"Set", Set_impl},
    {0, 0}
};

static void LuaInit(lua_State* L)
{
    int top = lua_gettop(L);

    // Register lua names
    luaL_register(L, MODULE_NAME, Module_methods);

    lua_pop(L, 1);
    assert(top == lua_gettop(L));
}

static dmExtension::Result Initialize(dmExtension::Params* params)
{
    // Init Lua
    LuaInit(params->m_L);
    printf("Registered %s Extension\n", MODULE_NAME);
    return dmExtension::RESULT_OK;
}

// Defold SDK uses a macro for setting up extension entry points:
//
// DM_DECLARE_EXTENSION(symbol, name, app_init, app_final, init, update, on_event, final)

// LIB_NAME is the C++ symbol that holds all relevant extension data.
// It must match the name field in the `ext.manifest`
DM_DECLARE_EXTENSION(LuaScriptInstance, LIB_NAME, 0, 0, Initialize, 0, 0, 0)
