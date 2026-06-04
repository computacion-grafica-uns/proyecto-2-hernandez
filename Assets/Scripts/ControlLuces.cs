using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ControlLuces : MonoBehaviour

{
    [Header("Las 3 luces - arrastrá desde la jerarquía")]
    public Light luzDireccional;
    public Light luzPuntual;
    public Light luzSpot;

    public Material[] materialesObjetos;
    public Vector3 pointLightPosition;

    void Update()
    {
        // Tecla 1 → toggle luz direccional
        if (Input.GetKeyDown(KeyCode.Alpha1))
            luzDireccional.enabled = !luzDireccional.enabled;

        // Tecla 2 → toggle luz puntual
        if (Input.GetKeyDown(KeyCode.Alpha2))
            luzPuntual.enabled = !luzPuntual.enabled;

        // Tecla 3 → toggle luz spot
        if (Input.GetKeyDown(KeyCode.Alpha3))
            luzSpot.enabled = !luzSpot.enabled;


        foreach(Material m in materialesObjetos)
        {
            m.SetVector("_PointLightPosition_w", pointLightPosition);
        }

        /*
         dento foreach
          m.SetVector(
                "_PointLightPosition_w",
                luzPuntual.transform.position
            );

            if(luzPuntual.enabled)
            {
                m.SetColor(
                    "_PointLightIntensity",
                    luzPuntual.color * luzPuntual.intensity
                );
            }
            else
            {
                m.SetColor(
                    "_PointLightIntensity",
                    Color.black
                );
            }
        */
    }
}