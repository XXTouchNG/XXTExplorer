#coding:utf-8

import sys
reload(sys)
sys.setdefaultencoding('utf8')
import json  
import types

def space_deep(deep):  
    lua_str = ""  
    for i in range(0,deep):  
        lua_str += '\t'  
    return lua_str  
  
def dic_to_lua_str(data,deep=0):  
    d_type = type(data)  
    if  d_type is types.StringTypes or d_type is str or d_type is types.UnicodeType:  
        return "\"" + data + "\""  
    elif d_type is types.BooleanType:  
        if data:  
            return 'true'  
        else:  
            return 'false'  
    elif d_type is types.IntType or d_type is types.LongType or d_type is types.FloatType:  
        return str(data)  
    elif d_type is types.ListType:  
        lua_str = "{\n"  
        lua_str += space_deep(deep+1)  
        for i in range(0,len(data)):  
            lua_str += dic_to_lua_str(data[i], deep+1)  
            if i < len(data)-1:  
                lua_str += ','  
        lua_str += '\n'  
        lua_str += space_deep(deep)  
        lua_str +=  '}'  
        return lua_str  
    elif d_type is types.DictType:  
        lua_str = "{\n"  
        data_len = len(data)  
        data_count = 0  
        for k,v in data.items():  
            data_count += 1  
            lua_str += space_deep(deep+1)  
            lua_str += '[\"' + str(k) + '\"]'    
            lua_str += ' = '  
            try:  
                lua_str += dic_to_lua_str(v, deep+1)  
                if data_count < data_len:  
                    lua_str += ',\n'  
  
            except Exception, e:  
                print 'error in ',k,v  
                raise  
        lua_str += '\n'  
        lua_str += space_deep(deep)  
        lua_str += '}'  
        return lua_str  
    else:  
        print d_type , 'is error'  
        return None  

if __name__ == "__main__":
    if len(sys.argv)==3:
        json_file = sys.argv[1]
        lua_file = sys.argv[2]
        json_io = open(json_file, "r")
        json_str = json_io.read()
        json_io.close()
        json_dic = json.loads(json_str)
        lua_str = dic_to_lua_str(json_dic)
        lua_str = "return " + lua_str
        lua_io = open(lua_file, "w+")
        lua_io.seek(0)
        lua_io.write(lua_str)
        lua_io.close()

