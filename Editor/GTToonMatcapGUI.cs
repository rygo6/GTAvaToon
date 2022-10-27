using System;
using System.Linq;
using System.Reflection;
using UnityEditor;
using UnityEngine;

namespace GeoTetra.GTAvaToon.Editor
{
    public class GTToonMatcapGUI : ShaderGUI
    {
        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            var target = materialEditor.target as Material;
            Debug.Assert(target != null, nameof(target) + " != null");
            
            // hrm
            target.renderQueue = 2010;
            
            // really we just doing this do hide the renderqueue field
            foreach (var materialProperty in properties)
            {
                materialEditor.ShaderProperty(materialProperty, materialProperty.displayName);
            }
        }
    }
    
    public class GTPropertyDrawer : MaterialPropertyDrawer
    {
        readonly string m_Tooltip;
        static readonly MethodInfo m_InternalDefaultMethod;
        
        static GTPropertyDrawer()
        {
            // yes really, otherwise you must duplicate so much code
            var methods = typeof(MaterialEditor).GetMethods(
                BindingFlags.NonPublic | 
                BindingFlags.Public | 
                BindingFlags.Instance);
            
            m_InternalDefaultMethod = methods.FirstOrDefault(
                m => m.Name.Equals("DefaultShaderPropertyInternal", 
                StringComparison.InvariantCulture));
        }
    
        public GTPropertyDrawer(string tooltip) => m_Tooltip = tooltip;
        
        public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor)
        {
            return 0;
        }

        public override void OnGUI(Rect position, MaterialProperty prop, GUIContent label, MaterialEditor editor)
        {
            if (!GUI.enabled)
                return;
            
            position.y += 1;
            position.height = EditorGUIUtility.singleLineHeight;
            GUI.Label(position, new GUIContent(String.Empty, m_Tooltip));
            m_InternalDefaultMethod.Invoke(editor, new object[] { prop, label });
        }
    }

    public class MaterialGTFoldoutHeaderDecorator : MaterialPropertyDrawer
    {
        readonly string m_Header;
        static readonly GUIStyle m_GUIStyle;
        bool m_FoldoutEnable = true;

        static MaterialGTFoldoutHeaderDecorator()
        {
            m_GUIStyle = new GUIStyle(EditorStyles.foldoutHeader);
            m_GUIStyle.fontSize += 2;
        }

        public MaterialGTFoldoutHeaderDecorator(string header) => m_Header = header;

        public override float GetPropertyHeight(
            MaterialProperty prop,
            string label,
            MaterialEditor editor)
        {
            return EditorGUIUtility.singleLineHeight;
        }

        public override void OnGUI(
            Rect position,
            MaterialProperty prop,
            string label,
            MaterialEditor editor)
        {
            EditorGUI.indentLevel = 0;
            GUI.enabled = true;
            EditorGUI.EndFoldoutHeaderGroup();
            
            position.y += 8f;
            position = EditorGUI.IndentedRect(position);

            m_FoldoutEnable = EditorGUI.BeginFoldoutHeaderGroup(position, m_FoldoutEnable, m_Header);
            GUI.enabled = m_FoldoutEnable;
            EditorGUI.indentLevel = 1;
        }
    }
}