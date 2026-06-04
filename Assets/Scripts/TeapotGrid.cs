using UnityEngine;

/// <summary>
/// Coloca 18 teteras en una grilla 3 filas x 6 columnas.
/// Asigna un material diferente a cada una segun la tabla del proyecto.
/// 
/// COMO USAR:
/// 1. Crear un GameObject vacio en la escena, llamarlo "TeapotGrid"
/// 2. Agregarle este script
/// 3. Asignar el prefab de la tetera en "Teapot Prefab"
/// 4. Asignar los 18 materiales en el array "Materials" (ver orden abajo)
/// 5. El script funciona en Edit Mode - las teteras aparecen sin hacer Play
/// </summary>
[ExecuteInEditMode]   // <-- esto hace que corra sin Play
public class TeapotGrid : MonoBehaviour
{
    [Header("Prefab")]
    public GameObject teapotPrefab;

    [Header("Espaciado")]
    public float spacingX = 2.0f;   // distancia horizontal entre teteras
    public float spacingZ = 2.5f;   // distancia entre filas

    /// <summary>
    /// ORDEN DE LOS 18 MATERIALES EN EL ARRAY:
    /// 
    /// Fila 0 - Blinn-Phong:
    ///   [0]  BP_Barro
    ///   [1]  BP_MetalPulido
    ///   [2]  BP_Vidrio
    ///   [3]  BP_Texture2D
    ///   [4]  BP_Procedural
    ///   [5]  BP_NormalMap
    ///
    /// Fila 1 - Cook-Torrance:
    ///   [6]  CT_Barro
    ///   [7]  CT_MetalPulido
    ///   [8]  CT_Vidrio
    ///   [9]  CT_Texture2D
    ///   [10] CT_Procedural
    ///   [11] CT_NormalMap
    ///
    /// Fila 2 - Toon Shader:
    ///   [12] Toon_Barro
    ///   [13] Toon_MetalPulido
    ///   [14] Toon_Vidrio
    ///   [15] Toon_Texture2D
    ///   [16] Toon_Procedural
    ///   [17] Toon_NormalMap
    /// </summary>
    [Header("Materiales (18 en orden: ver comentario)")]
    public Material[] materials = new Material[18];

    // Guarda referencias a las teteras instanciadas para poder regenerarlas
    public GameObject[] instances = new GameObject[18];

    // En Edit Mode, OnValidate se llama cada vez que cambiás algo en el Inspector
    /*private void OnValidate()
    {
        BuildGrid();
    }*/

    // En Play Mode se llama al iniciar
    private void Start()
    {
        //BuildGrid();
    }

    [ContextMenu("Regenerar Grilla")]   // boton derecho en el Inspector -> Regenerar
    /*public void BuildGrid()
    {
        if (teapotPrefab == null) return;

        // Destruir las teteras viejas (Edit Mode requiere DestroyImmediate)
        // Limpiamos todos los hijos del GameObject
        for (int i = transform.childCount - 1; i >= 0; i--)
        {
            //DestroyImmediate(transform.GetChild(i).gameObject);
            #if UNITY_EDITOR
                if (!Application.isPlaying)
                    DestroyImmediate(transform.GetChild(i).gameObject);
                else
                    Destroy(transform.GetChild(i).gameObject);
                #else
                Destroy(transform.GetChild(i).gameObject);
                #endif


        }

        int index = 0;
        // row = fila (0=BlinnPhong, 1=CookTorrance, 2=Toon)
        // col = columna (0=Barro, 1=Metal, 2=Vidrio, 3=Tex2D, 4=Proc, 5=NormalMap)
        for (int row = 0; row < 3; row++)
        {
            for (int col = 0; col < 6; col++)
            {
                Vector3 pos = transform.position
                            + new Vector3(col * spacingX, 0, row * spacingZ);

                GameObject teapot = (GameObject)UnityEditor.PrefabUtility.InstantiatePrefab(
                                        teapotPrefab, transform);
                teapot.transform.position   = pos;
                teapot.transform.localScale = Vector3.one*0.05f;
                teapot.name = GetName(row, col);

                // Asignar material si esta cargado
                if (index < materials.Length && materials[index] != null)
                {
                    Renderer rend = teapot.GetComponentInChildren<Renderer>();
                    if (rend != null)
                        rend.sharedMaterial = materials[index];
                }

                instances[index] = teapot;
                index++;
            }
        }
    }*/

    string GetName(int row, int col)
    {
        string[] shaders = { "BlinnPhong", "CookTorrance", "Toon" };
        string[] mats    = { "Barro", "Metal", "Vidrio", "Tex2D", "Procedural", "NormalMap" };
        return $"Tetera_{shaders[row]}_{mats[col]}";
    }
}
