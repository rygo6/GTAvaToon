using System.Collections;
using System.Linq;
using System.Collections.Generic;
using System.IO;
using Unity.EditorCoroutines.Editor;
using UnityEditor;
using UnityEngine;
using PackageInfo = UnityEditor.PackageManager.PackageInfo;

namespace GeoTetra.GTAvaUtil
{
    public class MenuUtilites
    {
        [MenuItem("Tools/GeoTetra/GTAvaToon/Check for Update...", false)]
        static void CheckForUpdate()
        {
            var list = UnityEditor.PackageManager.Client.List();
            while (!list.IsCompleted)
            { }
            PackageInfo package = list.Result.FirstOrDefault(q => q.name == "com.geotetra.gtavatoon");
            if (package == null)
            {
                EditorUtility.DisplayDialog("Not installed via UPM!",
                    "This upgrade option only works if you installed via UPM. Go to AvaCrypt github and reinstall via UPM if you wish to use this",
                    okText);
            }

            UnityEditor.PackageManager.Client.Add("https://github.com/rygo6/GTAvaToon.git");
        }
    }
}
