using UnityEditor;
using UnityEngine;
using Random = UnityEngine.Random;

namespace GeoTetra.GTAvaToon.Editor
{
    public class GTToonMatcapGUI : ShaderGUI
    {
        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            var target = materialEditor.target as Material;
            Debug.Assert(target != null, nameof(target) + " != null");
            
            // Avatars set to different render queues which share the _GTToonGrabTexture will produce
            // issues between each other if not on the same renderqueue. So just hide and override.
            target.renderQueue = 2010;
            
            // really we just doing this do hide the renderqueue field
            foreach (var materialProperty in properties)
            {
                if (materialProperty.name == "_DepthId" && materialProperty.floatValue == 1)
                {
                    // set ids to different values initially randomly so everyone ends up with
                    // higher chance of drawing line on each other, and materials initially draw
                    // lines between each other
                    materialProperty.floatValue = Random.Range(.01f, 1f);
                }
                materialEditor.ShaderProperty(materialProperty, materialProperty.displayName);
            }
        }
    }
}