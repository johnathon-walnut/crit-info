#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <regex>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <dhooks>

#if defined (MAXPLAYERS)
    #undef MAXPLAYERS
    #define MAXPLAYERS 101
#endif

public Plugin myinfo = {
    name = "Crit Info",
    author = "mfed",
    description = "Show crit info on shot",
}

Address m_iLastCritCheckFrame;
Address m_bCurrentCritIsRandom;
Address m_flCritTime;
Address m_flCritTokenBucket;
Address m_iCurrentSeed;
Address m_nCritChecks;
Address m_flLastRapidFireCritCheckTime;
Address m_nCritSeedRequests;
Address m_flLastCritCheckTime;

bool IsValidOffset(Address pAddr)
{
    return pAddr != Address_Null;
}

void InitCritInfo()
{
    GameData hGameData = LoadGameConfigFile("crit-info");
    if (hGameData == null)
    {
        LogError("Failed to load crit-info.txt");
        return;
    }

    DHookSetup hDetour = DHookCreateFromConf(hGameData, "CTFWeaponBase::CalcIsAttackCritical"); 
    if (!hDetour)
    {
        SetFailState("Failed to find signature for CalcIsAttackCritical");
    }

    if (!DHookEnableDetour(hDetour, true, Detour_CalcIsAttackCritical))
    {
        SetFailState("Failed to enable detour for CalcIsAttackCritical");
    }

    m_iLastCritCheckFrame = view_as<Address> ( GameConfGetOffset(hGameData, "m_iLastCritCheckFrame") );
    m_bCurrentCritIsRandom = view_as<Address> ( GameConfGetOffset(hGameData, "m_bCurrentCritIsRandom") );
    m_flCritTime = view_as<Address> ( GameConfGetOffset(hGameData, "m_flCritTime") );
    m_flCritTokenBucket = view_as<Address> ( GameConfGetOffset(hGameData, "m_flCritTokenBucket") );
    m_iCurrentSeed = view_as<Address> ( GameConfGetOffset(hGameData, "m_iCurrentSeed") );
    m_nCritChecks = view_as<Address> ( GameConfGetOffset(hGameData, "m_nCritChecks") );
    m_flLastRapidFireCritCheckTime = view_as<Address> ( GameConfGetOffset(hGameData, "m_flLastRapidFireCritCheckTime") );
    m_nCritSeedRequests = view_as<Address> ( GameConfGetOffset(hGameData, "m_nCritSeedRequests") );
    m_flLastCritCheckTime = view_as<Address> ( GameConfGetOffset(hGameData, "m_flLastCritCheckTime") );

    if (!IsValidOffset(m_iLastCritCheckFrame) || !IsValidOffset(m_bCurrentCritIsRandom) || !IsValidOffset(m_flCritTime) || !IsValidOffset(m_flCritTokenBucket) || !IsValidOffset(m_iCurrentSeed) || !IsValidOffset(m_nCritChecks) || !IsValidOffset(m_flLastRapidFireCritCheckTime) || !IsValidOffset(m_nCritSeedRequests) || !IsValidOffset(m_flLastCritCheckTime))
    {
        SetFailState("Failed to find offsets for CalcIsAttackCritical");
    }

    delete hGameData;    
}

#define Pointer Address
#define nullptr Address_Null

#define int(%1) view_as<int>(%1)
#define ptr(%1) view_as<Pointer>(%1)  

stock int ReadByte(Pointer pAddr)
{
    if(pAddr == nullptr)
    {
        return -1;
    }
    
    return LoadFromAddress(pAddr, NumberType_Int8);
}

stock int ReadWord(Pointer pAddr)
{
    if(pAddr == nullptr)
    {
        return -1;
    }
    
    return LoadFromAddress(pAddr, NumberType_Int16);
}

stock int ReadInt(Pointer pAddr)
{
    if(pAddr == nullptr)
    {
        return -1;
    }
    
    return LoadFromAddress(pAddr, NumberType_Int32);
}  

stock Pointer Transpose(Pointer pAddr, int iOffset)
{
    return ptr(int(pAddr) + iOffset);
}

stock int Dereference(Pointer pAddr, int iOffset = 0)
{
    if(pAddr == nullptr)
    {
        return -1;
    }
    
    return ReadInt(Transpose(pAddr, iOffset));
}

stock int DereferenceBool(Pointer pAddr, int iOffset = 0)
{
    if(pAddr == nullptr)
    {
        return false;
    }
    
    return ReadByte(Transpose(pAddr, iOffset));
}

public MRESReturn Detour_CalcIsAttackCritical(Address pThis, DHookParam hParams)
{
    PrintToChatAll(" ");
    PrintToChatAll(" ");

    PrintToChatAll("m_iLastCritCheckFrame: %d", Dereference(pThis + m_iLastCritCheckFrame));
    PrintToChatAll("m_iCurrentSeed: %d", Dereference(pThis + m_iCurrentSeed));
    PrintToChatAll("m_bCurrentCritIsRandom: %d", DereferenceBool(pThis + m_bCurrentCritIsRandom));
    PrintToChatAll("m_flCritTime: %f", view_as<float>(Dereference(pThis + m_flCritTime)));
    PrintToChatAll("m_flLastCritCheckTime: %f", view_as<float>(Dereference(pThis + m_flLastCritCheckTime)));
    // PrintToChatAll("m_flLastRapidFireCritCheckTime: %f", view_as<float>(Dereference(pThis + m_flLastRapidFireCritCheckTime)));
    PrintToChatAll("m_flCritTokenBucket: %f", view_as<float>(Dereference(pThis + m_flCritTokenBucket)));
    PrintToChatAll("m_nCritChecks: %d", Dereference(pThis + m_nCritChecks));
    PrintToChatAll("m_nCritSeedRequests: %d", Dereference(pThis + m_nCritSeedRequests));

    return MRES_Supercede;
}

public void OnPluginStart()
{
    InitCritInfo();
}