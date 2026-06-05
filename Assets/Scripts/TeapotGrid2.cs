using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TeapotGrid2 : MonoBehaviour

{
    [Header("Prefab")]
    public GameObject teapotPrefab;

    [Header("Espaciado")]
    public float spacingX = 2f;
    public float spacingZ = 2.5f;

    [Header("Materiales (18)")]
    public Material[] materials = new Material[18];

    [HideInInspector]
    public GameObject[] instances = new GameObject[18];

    void Start()
    {
        BuildGrid();
    }

    [ContextMenu("Regenerar Grilla")]
    public void BuildGrid()
    {
        if (teapotPrefab == null)
        {
            Debug.LogWarning("No hay prefab asignado.");
            return;
        }

        // Borra las teteras existentes
        for (int i = transform.childCount - 1; i >= 0; i--)
        {
            Destroy(transform.GetChild(i).gameObject);
        }

        instances = new GameObject[18];

        int index = 0;

        for (int row = 0; row < 3; row++)
        {
            for (int col = 0; col < 6; col++)
            {
                Vector3 pos = transform.position +
                              new Vector3(col * spacingX, 0, row * spacingZ);

                GameObject teapot = Instantiate(
                    teapotPrefab,
                    pos,
                    Quaternion.identity,
                    transform);

                teapot.transform.localScale = Vector3.one * 0.05f;
                teapot.name = GetName(row, col);

                if (index < materials.Length && materials[index] != null)
                {
                    Renderer rend = teapot.GetComponentInChildren<Renderer>();

                    if (rend != null)
                        rend.material = materials[index];
                }

                instances[index] = teapot;
                index++;
            }
        }

        Debug.Log($"Se generaron {index} teteras.");
    }

    string GetName(int row, int col)
    {
        string[] shaders = { "BlinnPhong", "CookTorrance", "Toon" };
        string[] mats = { "Barro", "Metal", "Vidrio", "Tex2D", "Procedural", "NormalMap" };

        return $"Tetera_{shaders[row]}_{mats[col]}";
    }
}