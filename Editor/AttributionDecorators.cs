using UnityEditor;
using UnityEngine;

namespace GeoTetra.GTAvaToon.Editor
{
    /// <summary>
    /// Place the attribute [OutlineAttribution] above a single field in your ShaderLabel Properties
    /// section to draw the appropriate attribution in the Material Inspector UI.
    ///
    /// Shader "ExampleShader"
    /// {	
    /// 	Properties
    ///     {
    ///         [OutlineAttribution]
    ///         _OutlineColor ("Outline Color", Color) = (0,0,0,1)
    ///
    /// ... 
    /// 
    /// </summary>
    public class MaterialOutlineAttributionDecorator : MaterialPropertyDrawer
    {
        static readonly GUIStyle m_GUIStyle;
        
        static MaterialOutlineAttributionDecorator()
        {
            m_GUIStyle = new GUIStyle(EditorStyles.linkLabel);
            m_GUIStyle.fontSize -= 1;
        }
        
        public override void OnGUI(
            Rect position,
            MaterialProperty prop,
            string label,
            MaterialEditor editor)
        {
            position = EditorGUI.IndentedRect(position);
            GUI.Label(position, "_________________________________", m_GUIStyle);
            if (GUI.Button(position, "Outline From GeoTetra AvaToon", m_GUIStyle))
            {
                Application.OpenURL("https://github.com/rygo6/GTAvaToon");
            }
        }
    }
}