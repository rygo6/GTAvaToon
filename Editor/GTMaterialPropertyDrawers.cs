using System;
using System.Linq;
using System.Reflection;
using UnityEditor;
using UnityEngine;

namespace GeoTetra.GTAvaToon.Editor
{
    public class TooltipDrawer : MaterialPropertyDrawer
    {
        readonly string m_Tooltip;
        static readonly MethodInfo m_InternalDefaultMethod;
        
        static TooltipDrawer()
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
    
        public TooltipDrawer(string tooltip) => m_Tooltip = tooltip;
        
        public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor)
        {
            return 0;
        }

        public override void OnGUI(Rect position, MaterialProperty prop, GUIContent label, MaterialEditor editor)
        {
            position.y += 1;
            position.height = EditorGUIUtility.singleLineHeight;
            GUI.Label(position, new GUIContent(String.Empty, m_Tooltip));
            m_InternalDefaultMethod.Invoke(editor, new object[] { prop, label });
        }
    }

    public class MaterialLargeHeaderDecorator : MaterialPropertyDrawer
    {
        readonly string m_Header;
        static readonly GUIStyle m_GUIStyle;
        bool m_FoldoutEnable = true;

        static MaterialLargeHeaderDecorator()
        {
            m_GUIStyle = new GUIStyle(EditorStyles.label);
            m_GUIStyle.fontSize += 2;
        }

        public MaterialLargeHeaderDecorator(string header) => m_Header = header;

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
            
            GUI.Box(position, string.Empty);
            EditorGUI.DropShadowLabel(position, m_Header, m_GUIStyle);
            
            EditorGUI.indentLevel = 1;
        }
    }
}