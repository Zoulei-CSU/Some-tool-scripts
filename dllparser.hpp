#ifndef DLLPARSER_H
#define DLLPARSER_H

#include <Windows.h>
#include <string>
#include <map>
#include <functional>

using namespace std;

class DllParser
{
public:
	DllParser() : m_hMod(nullptr){}
	~DllParser(){ unLoad(); }

	bool load(const std::string &dllPath)
	{
		m_hMod = LoadLibraryA(dllPath.data());
		if (m_hMod == nullptr)
		{
			printf("LoadLibrary failed.\n");
			return false;
		}
		return true;
	}

	bool unLoad()
	{
		if (m_hMod == nullptr)
			return true;

		auto b = FreeLibrary(m_hMod);
		if (!b)
			return false;

		m_hMod = nullptr;
		return true;
	}

	template <typename T>
	std::function<T> getFunction(const std::string &funcName)
	{
		auto it = m_map.find(funcName);

		if (it == m_map.end())
		{
			auto addr = GetProcAddress(m_hMod, funcName.c_str());
			if (!addr)
				return nullptr;

			m_map.insert(std::make_pair(funcName, addr));
			it = m_map.find(funcName);
		}

		return std::function<T>( (T*) (it->second) );
	}

	template <typename T, typename... Args>
	typename std::result_of<std::function<T>(Args...)>::type executeFunc(const std::string &funcName, Args&&... args)
	{
		auto f = getFunction<T>(funcName);
		if (f == nullptr)
		{
			std::string s = "can not find function : " + funcName;
			throw std::exception(s.c_str());
		}

		return f(std::forward<Args>(args)...);
	}

private:
	HMODULE m_hMod;
	std::map<std::string, FARPROC> m_map;
};

/*
auto max = executeFunc<int(int,int)>("Max", 5, 8);
auto ret = executeFunc<int(int)>("Get", 5);
*/

#endif //DLLPARSER_H