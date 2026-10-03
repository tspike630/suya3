using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using AClockworkBerry;
using Cysharp.Threading.Tasks;
using Jyx2.Middleware;
using Jyx2.MOD;
using Jyx2.MOD.ModV2;
using Jyx2.ResourceManagement;
using MOD.UI;
using UnityEditor;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace Jyx2
{
    /// <summary>
    /// 游戏运行时的初始化
    /// </summary>
    public static class RuntimeEnvSetup
    {
        private static bool _isSetup;
        public static MODRootConfig CurrentModConfig { get; private set; } = null;
        private static GameModBase _currentMod;
        private static string _selectedModId;

        public static string CurrentModId => _currentMod?.Id;

        public static void SetCurrentMod(GameModBase mod)
        {
            _currentMod = mod;
            if (!string.IsNullOrEmpty(mod?.Id))
                _selectedModId = mod.Id;
        }

        public static GameModBase GetCurrentMod() => _currentMod;

        public static bool IsLoading { get; private set; } = false;

        public static void ForceClear()
        {
            _isSetup = false;
            CurrentModConfig = null;
            _currentMod = null;
            IsLoading = false;
            _successInited = false;
            LuaManager.Clear();
        }

        private static bool _successInited = false;
        
        public static async UniTask<bool> Setup()
        {
            if (_isSetup) return false;

            try
            {
                if (IsLoading)
                {
                    //同时调用了Setup的地方都应该挂起
                    await UniTask.WaitUntil(() => _isSetup);
                    return _successInited;
                }

                IsLoading = true;

                DebugInfoManager.Init();

                //全局配置表
                var t = Resources.Load<GlobalAssetConfig>("GlobalAssetConfig");
                if (t != null)
                {
                    GlobalAssetConfig.Instance = t;
                    await t.OnLoad();
                }
 
//为了Editor内调试方便
#if UNITY_EDITOR
                var editorModLoader = new GameModEditorLoader();
                var path = SceneManager.GetActiveScene().path;
                Debug.Log("当前调试场景："+path);

                //调试工具
                if (path.StartsWith("Assets/Jyx2Tools/Jyx2SkillEditor"))
                {
                    foreach (var mod in await editorModLoader.LoadMods())
                    {
                        if (mod.Id == "SAMPLE")
                        {
                            SetCurrentMod(mod);
                            break;
                        }
                    }
                }
                else if (path.Contains("Assets/Mods/"))
                {
                    var editorModId = path.Split('/')[2];
                    Debug.Log("当前场景所属Mod："+ editorModId);

                    foreach (var mod in await editorModLoader.LoadMods())
                    {
                        if (mod.Id == editorModId)
                        {
                            SetCurrentMod(mod);
                            break;
                        }
                    }
                }
#endif
                await ResLoader.Init();
                if (_currentMod == null)
                    await RestoreSelectedMod();
                if (_currentMod == null)
                    throw new Exception("没有选中模组");
                await ResLoader.LaunchMod(_currentMod);

                CurrentModConfig = await ResLoader.LoadAsset<MODRootConfig>("Assets/ModSetting.asset");
                if (CurrentModConfig == null)
                    throw new Exception("找不到 ModSetting，模组=" + _currentMod.Id);
                GameSettingManager.Init();
                await Jyx2ResourceHelper.Init();
                LuaManager.LuaMod_Init();
                _isSetup = true;
                IsLoading = false;
                _successInited = true;
                return true;
            }
            catch (Exception e)
            {
                string where = "";
                if (!string.IsNullOrEmpty(e.StackTrace))
                {
                    int nl = e.StackTrace.IndexOf('\n');
                    where = (nl > 0 ? e.StackTrace.Substring(0, nl) : e.StackTrace).Trim();
                }
                string msg = "<color=red>" + e.Message + "\n" + where + "</color>";
                Debug.LogError(msg);
                Debug.LogError(e.ToString());
                ScreenLogger.Instance.enabled = true;
                ModPanelNew.SwitchSceneTo();
                _successInited = false;
                MessageBox.ShowMessage(msg);
                return false;
            }
        }

        static async UniTask RestoreSelectedMod()
        {
#if UNITY_EDITOR
            var mods = await new GameModEditorLoader().LoadMods();
            GameModBase fallback = null;
            foreach (var mod in mods)
            {
                if (fallback == null && string.Equals(mod.Id, "SAMPLE", StringComparison.OrdinalIgnoreCase))
                    fallback = mod;
                if (!string.IsNullOrEmpty(_selectedModId) &&
                    string.Equals(mod.Id, _selectedModId, StringComparison.OrdinalIgnoreCase))
                {
                    _currentMod = mod;
                    return;
                }
            }

            _currentMod = fallback;
#else
            await UniTask.CompletedTask;
#endif
        }
    }
}
