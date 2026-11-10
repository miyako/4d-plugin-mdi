#include "4DPlugin-JSON.h"
#include "C_TEXT.h"
#include "ARRAY_TEXT.h"
#include "PrivateTypes.h"
#include "EntryPoints.h"
#include <cassert>
#include <cstdlib>
#include <cstring>
#include <iostream>
#include <map>
#include <set>

// Only the engine is substituted. All PA_* operations run the bundled SDK.
static bool nullEmpty;
static bool stringifyMismatch;
static std::set<PA_Unichar *> strings;
static std::map<PA_Handle, size_t> handles;
struct Object {
    size_t refs = 1;
    std::map<CUTF16String, PA_Variable> properties;
};
static std::set<Object *> objects;

static CUTF16String text(const PA_Unistring &s) {
    PA_Unichar *buffer = s.fString;
    if (!buffer) {
        assert(s.fLength == 0);
        return {};
    }
    assert(strings.count(buffer));
    assert(buffer[s.fLength] == 0);
    return CUTF16String(buffer, s.fLength);
}

static PA_Unistring makeString(const CUTF16String &s) {
    PA_Unistring result = {};
    result.fLength = static_cast<PA_long32>(s.size());
    if (!s.empty() || !nullEmpty) {
        result.fString = static_cast<PA_Unichar *>(
            malloc((s.size() + 1) * sizeof(PA_Unichar)));
        assert(result.fString);
        memcpy(result.fString, s.c_str(), (s.size() + 1) * sizeof(PA_Unichar));
        PA_Unichar *buffer = result.fString;
        assert(strings.insert(buffer).second);
    }
    return result;
}

static void disposeString(PA_Unistring s) {
    PA_Unichar *buffer = s.fString;
    if (buffer) {
        assert(strings.erase(buffer) == 1);
        free(buffer);
    }
}

static Object *newObject() {
    Object *o = new Object;
    objects.insert(o);
    return o;
}

static void clear(PA_Variable &v);
static PA_Variable copy(PA_Variable v) {
    if (v.fType == eVK_Unistring)
        v.uValue.fString = makeString(text(v.uValue.fString));
    if ((v.fType == eVK_Object || v.fType == eVK_Collection) && v.uValue.fObject) {
        auto o = static_cast<Object *>(v.uValue.fObject);
        assert(objects.count(o));
        ++o->refs;
    }
    return v;
}

static void clear(PA_Variable &v) {
    if (v.fType == eVK_Unistring)
        disposeString(v.uValue.fString);
    if (v.fType == eVK_ArrayUnicode && v.uValue.fArray.fData) {
        for (PA_long32 i = 0; i <= v.uValue.fArray.fNbElements; ++i)
            disposeString((*reinterpret_cast<PA_Unistring **>(v.uValue.fArray.fData))[i]);
        PA_DisposeHandle(v.uValue.fArray.fData);
    }
    if ((v.fType == eVK_Object || v.fType == eVK_Collection) && v.uValue.fObject) {
        auto o = static_cast<Object *>(v.uValue.fObject);
        assert(objects.count(o));
        assert(o->refs > 0);
        if (--o->refs == 0) {
            for (auto &p : o->properties) clear(p.second);
            objects.erase(o);
            delete o;
        }
    }
    v = {};
    v.fType = eVK_Undefined;
}

static void engine(short selector, EngineBlock *eb) {
    switch (selector) {
        case EX_CREATE_UNISTRING:
            eb->fUniString1 = makeString(CUTF16String(
                reinterpret_cast<PA_Unichar *>(eb->fHandle)));
            break;
        case EX_DISPOSE_UNISTRING:
            disposeString(eb->fUniString1);
            break;
        case EX_SET_UNISTRING: {
            CUTF16String content(reinterpret_cast<PA_Unichar *>(eb->fHandle));
            disposeString(eb->fUniString1);
            eb->fUniString1 = makeString(content);
            break;
        }
        case EX_CLEAR_VARIABLE:
            clear(*static_cast<PA_Variable *>(eb->fPtr1));
            break;
        case EX_VARIABLE_TO_STRING: {
            auto v = reinterpret_cast<PA_Variable *>(eb->fHandle);
            assert(v->fType == eVK_Unistring);
            text(v->uValue.fString);
            eb->fUniString1 = v->uValue.fString;
            break;
        }
        case EX_SET_OBJ_VALUE: {
            auto o = static_cast<Object *>(eb->fPtr1);
            assert(objects.count(o));
            auto &old = o->properties[text(eb->fUniString1)];
            clear(old);
            old = copy(*static_cast<PA_Variable *>(eb->fPtr2));
            break;
        }
        case EX_GET_OBJ_VALUE: {
            auto o = static_cast<Object *>(eb->fPtr1);
            assert(objects.count(o));
            *static_cast<PA_Variable *>(eb->fPtr2) =
                copy(o->properties.at(text(eb->fUniString1)));
            break;
        }
        case EX_EXECUTE_COMMAND_BY_ID: {
            auto args = static_cast<PA_Variable **>(eb->fPtr1);
            auto result = static_cast<PA_Variable *>(eb->fPtr2);
            *result = {};
            if (eb->fParam1 == 1231) {
                auto o = static_cast<Object *>(args[0]->uValue.fObject);
                assert(objects.count(o));
                result->fType = eVK_Boolean;
                result->uValue.fBoolean =
                    o->properties.count(text(args[1]->uValue.fString)) != 0;
            } else if (eb->fParam1 == 1225) {
                auto source = static_cast<Object *>(args[0]->uValue.fObject);
                Object *o = newObject();
                for (auto &p : source->properties) o->properties[p.first] = copy(p.second);
                result->fType = eVK_Object;
                result->uValue.fObject = o;
            } else if (eb->fParam1 == 1217) {
                if (stringifyMismatch) {
                    *result = copy(*args[0]);
                } else {
                    result->fType = eVK_Unistring;
                    result->uValue.fString = makeString({'{', '}', 0x65e5, 0xd83d, 0xde00});
                }
            } else {
                std::cerr << "Unexpected command " << eb->fParam1 << "\n";
                abort();
            }
            break;
        }
        case EX_HANDLE_MANAGER: {
            PA_Handle h = eb->fHandle;
            switch (eb->fParam1) {
                case 1:
                    h = static_cast<PA_Handle>(malloc(sizeof(char *)));
                    assert(h);
                    *h = static_cast<char *>(calloc(1, eb->fParam2 ? eb->fParam2 : 1));
                    assert(*h);
                    handles[h] = eb->fParam2;
                    eb->fHandle = h;
                    break;
                case 2:
                    assert(handles.erase(h) == 1);
                    free(*h);
                    free(h);
                    break;
                case 3:
                    assert(handles.count(h));
                    *h = static_cast<char *>(realloc(*h, eb->fParam2 ? eb->fParam2 : 1));
                    assert(*h);
                    handles[h] = eb->fParam2;
                    break;
                case 4: eb->fParam2 = handles.at(h); break;
                case 5: eb->fParam3 = reinterpret_cast<sLONG_PTR>(*h); break;
                case 6: break;
                default: abort();
            }
            break;
        }
        default:
            std::cerr << "Unexpected engine selector " << selector << "\n";
            abort();
    }
}

extern "C" void PluginMain(PA_long32, PA_PluginParameters) {}

static void balanced() {
    if (!strings.empty() || !handles.empty() || !objects.empty()) {
        std::cerr << "Ownership imbalance: strings=" << strings.size()
                  << " handles=" << handles.size() << " objects=" << objects.size() << "\n";
        abort();
    }
}

static void setters() {
    const wchar_t *wide[] = {L"", L"ASCII", L"\u65e5", L"\U0001f600"};
    const char *utf8[] = {"", "ASCII", "\xe6\x97\xa5", "\xf0\x9f\x98\x80"};
    const CUTF16String expected[] = {{}, {'A','S','C','I','I'}, {0x65e5}, {0xd83d,0xde00}};
    for (size_t i = 0; i < 4; ++i) {
        Object *o = newObject();
        for (int repeat = 0; repeat < 20; ++repeat) {
            ob_set_s(o, "key", utf8[i]);
            assert(text(o->properties.at({'k','e','y'}).uValue.fString) == expected[i]);
            ob_set_s(o, L"key", utf8[i]);
            assert(text(o->properties.at({'k','e','y'}).uValue.fString) == expected[i]);
            ob_set_a(o, L"key", wide[i]);
            assert(text(o->properties.at({'k','e','y'}).uValue.fString) == expected[i]);
            ob_set_a(o, L"key", &expected[i]);
            assert(text(o->properties.at({'k','e','y'}).uValue.fString) == expected[i]);
            // Churn unrelated allocations before reading the property again.
            auto churn = PA_CreateUnistring(const_cast<PA_Unichar *>(expected[1].c_str()));
            PA_DisposeUnistring(&churn);
            assert(text(o->properties.at({'k','e','y'}).uValue.fString) == expected[i]);
        }
        PA_DisposeObject(o);
        balanced();
    }
    ob_set_s(nullptr, "key", "value");
    ob_set_a(nullptr, L"key", L"value");
    balanced();
}

static void getters() {
    Object *o = newObject();
    const char *fixtures[] = {"", "ASCII", "\xe6\x97\xa5", "\xf0\x9f\x98\x80"};
    for (auto fixture : fixtures) {
        ob_set_s(o, "key", fixture);
        CUTF8String output;
        assert(ob_get_a(o, L"key", &output));
        assert(output == CUTF8String(reinterpret_cast<const uint8_t *>(fixture)));
        assert(!ob_get_b(o, L"key"));
        assert(ob_get_n(o, L"key") == 0);
        assert(ob_get_c(o, L"key") == nullptr);
        assert(ob_get_o(o, L"key") == nullptr);
        size_t expectedStrings = nullEmpty && fixture[0] == 0 ? 0 : 1;
        assert(strings.size() == expectedStrings);
    }
    // Every mismatched getter must release reference-bearing property results too.
    for (bool collection : {false, true}) {
        Object *child = newObject();
        if (collection) ob_set_c(o, L"key", child);
        else ob_set_o(o, L"key", child);
        assert(child->refs == 1);
        CUTF8String output = {'u','n','c','h','a','n','g','e','d'};
        auto original = output;
        assert(ob_get_a(o, L"key", &output));
        assert(output == original);
        assert(child->refs == 1);
        assert(!ob_get_b(o, L"key"));
        assert(child->refs == 1);
        assert(ob_get_n(o, L"key") == 0);
        assert(child->refs == 1);
        if (collection) assert(ob_get_o(o, L"key") == nullptr);
        else assert(ob_get_c(o, L"key") == nullptr);
        assert(child->refs == 1);
    }
    ob_set_b(o, L"key", true);
    assert(ob_get_b(o, L"key"));
    ob_set_n(o, L"key", 12.5);
    assert(ob_get_n(o, L"key") == 12.5);
    CUTF8String missing = {'x'};
    assert(!ob_get_a(o, L"missing", &missing));
    assert(missing == CUTF8String({'x'}));
    PA_DisposeObject(o);
    balanced();
}

static void handoffs() {
    Object *o = newObject();
    ob_set_o(o, L"object", newObject());
    ob_set_c(o, L"collection", newObject());
    auto object = static_cast<Object *>(ob_get_o(o, L"object"));
    auto collection = static_cast<Object *>(ob_get_c(o, L"collection"));
    assert(object->refs == 2 && collection->refs == 2);
    CUTF8String json;
    ob_stringify(o, &json);
    assert(json == CUTF8String(reinterpret_cast<const uint8_t *>("{}\xe6\x97\xa5\xf0\x9f\x98\x80")));
    stringifyMismatch = true;
    auto original = json;
    ob_stringify(o, &json);
    assert(json == original);
    assert(objects.size() == 3 && object->refs == 2 && collection->refs == 2);
    PA_DisposeObject(o);
    assert(objects.count(object) && object->refs == 1);
    assert(objects.count(collection) && collection->refs == 1);
    PA_DisposeObject(object);
    PA_DisposeCollection(collection);
    balanced();
}

static void arrays() {
    PA_Variable a = PA_CreateVariable(eVK_ArrayUnicode);
    PA_ResizeArray(&a, 3);
    const CUTF16String fixtures[] = {{}, {'A'}, {0x65e5}, {0xd83d,0xde00}};
    for (int repeat = 0; repeat < 20; ++repeat) {
        for (int i = 0; i < 4; ++i) {
            auto s = PA_CreateUnistring(const_cast<PA_Unichar *>(fixtures[i].c_str()));
            PA_SetStringInArray(a, i, &s);
        }
        ARRAY_TEXT copied;
        BytePtr params[] = {reinterpret_cast<BytePtr>(&a)};
        copied.fromParamAtIndex(params, 1);
        for (int i = 0; i < 4; ++i) {
            auto borrowed = PA_GetStringInArray(a, i);
            assert(text(borrowed) == fixtures[i]);
            auto replacement = PA_CreateUnistring(const_cast<PA_Unichar *>(fixtures[1].c_str()));
            PA_SetStringInArray(a, i, &replacement);
            CUTF16String output;
            copied.copyUTF16StringAtIndex(&output, i);
            assert(output == fixtures[i]);
        }
        PA_Variable b = PA_CreateVariable(eVK_Undefined);
        BytePtr output[] = {reinterpret_cast<BytePtr>(&b)};
        copied.toParamAtIndex(output, 1);
        for (int i = 0; i < 4; ++i)
            assert(text(PA_GetStringInArray(b, i)) == fixtures[i]);
        PA_ResizeArray(&b, 1);
        PA_ClearVariable(&b);
    }
    // The setter rejects these without taking ownership.
    for (int rejection = 0; rejection < 5; ++rejection) {
        auto s = PA_CreateUnistring(const_cast<PA_Unichar *>(fixtures[1].c_str()));
        auto destination = a;
        int index = 1;
        if (rejection == 0) destination.fType = eVK_Longint;
        if (rejection == 1) index = -1;
        if (rejection == 2) index = 4;
        if (rejection == 3) destination.uValue.fArray.fData = nullptr;
        PA_SetStringInArray(destination, index, rejection == 4 ? nullptr : &s);
        assert(text(s) == fixtures[1]);
        PA_DisposeUnistring(&s);
    }
    PA_ResizeArray(&a, 0);
    PA_ClearVariable(&a);
    balanced();
}

static void scalar() {
    for (const CUTF16String &s : {CUTF16String(), CUTF16String({'A'}),
                                CUTF16String({0x65e5}), CUTF16String({0xd83d,0xde00})}) {
        auto input = PA_CreateUnistring(const_cast<PA_Unichar *>(s.c_str()));
        C_TEXT wrapper;
        BytePtr parameters[] = {reinterpret_cast<BytePtr>(&input)};
        wrapper.fromParamAtIndex(parameters, 1);
        PA_DisposeUnistring(&input);
        assert(CUTF16String(wrapper.getUTF16StringPtr(), wrapper.getUTF16Length()) == s);
        auto result = PA_CreateUnistring(const_cast<PA_Unichar *>(s.c_str()));
        auto ptr = &result;
        wrapper.setReturn(reinterpret_cast<sLONG_PTR *>(&ptr));
        assert(text(result) == s);
        PA_DisposeUnistring(&result);
        CUTF8String utf8;
        wrapper.copyUTF8String(&utf8);
        wrapper.setUTF8String(&utf8);
        assert(CUTF16String(wrapper.getUTF16StringPtr(), wrapper.getUTF16Length()) == s);
    }
    balanced();
}

int main(int argc, char **argv) {
    assert(argc == 3);
    nullEmpty = std::string(argv[2]) == "null";
    gCall4D = engine;
    std::string mode = argv[1];
    if (mode == "setters") setters();
    else if (mode == "getters") getters();
    else if (mode == "handoffs") handoffs();
    else if (mode == "arrays") arrays();
    else if (mode == "scalar") scalar();
    else abort();
    std::cout << mode << " " << argv[2] << ": PASS\n";
}
