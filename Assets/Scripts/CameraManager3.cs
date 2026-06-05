using System.Collections;
using System.Collections.Generic;
using UnityEngine;

using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraManager3 : MonoBehaviour

{
    [Header("Referencias")]
    public TeapotGrid2 grid;

    [Header("Configuración Orbital")]
    public float sensibilidadRotacion = 3f;
    public float sensibilidadZoom = 10f;
    public float minDistancia = 2f;
    public float maxDistancia = 500f;

    [Header("Configuración FPS")]
    public float velocidadFPS = 5f;
    public float sensibilidadFPS = 2f;

    // Scripts de cámara
    private CO camaraOrbital;
    private CamaraFPSA camaraFPS;

    private bool modoFPS = false;
    private int indiceActual = -1;

    void Start()
    {
        CrearCamaraOrbital();
        CrearCamaraFPS();

        // Empieza en modo orbital
        camaraFPS.gameObject.SetActive(false);
        VerTodaLaEscena();
    }

    void CrearCamaraOrbital()
    {
        GameObject go = new GameObject("CamaraOrbital");
        go.transform.SetParent(this.transform);

        go.AddComponent<Camera>();
        camaraOrbital = go.AddComponent<CO>();

        camaraOrbital.sensibilidadRotacion = sensibilidadRotacion;
        camaraOrbital.sensibilidadZoom     = sensibilidadZoom;
        camaraOrbital.minDistancia         = minDistancia;
        camaraOrbital.maxDistancia         = maxDistancia;
    }

    void CrearCamaraFPS()
    {
        GameObject go = new GameObject("CamaraFPSA");
        go.transform.SetParent(this.transform);

        go.AddComponent<Camera>();
        camaraFPS = go.AddComponent<CamaraFPSA>();

        camaraFPS.velocidad      = velocidadFPS;
        camaraFPS.sensibilidad   = sensibilidadFPS;
    }

    void Update()
    {
        if (Input.GetKeyDown(KeyCode.P))
        {
            modoFPS = !modoFPS;
            camaraOrbital.gameObject.SetActive(!modoFPS);
            camaraFPS.gameObject.SetActive(modoFPS);

            if (modoFPS)
            {
                Vector3 centro = grid.transform.position + new Vector3(5f, 1f, 2.5f);
                camaraFPS.Teleportar(centro + new Vector3(0, 0.6f, -10f), centro);
            }
        }

        if (!modoFPS)
            UpdateOrbital();
        else
            UpdateFPS();
    }

    void UpdateOrbital()
    {
        if (Input.GetKeyDown(KeyCode.Space))
            VerTodaLaEscena();

        if (Input.GetKeyDown(KeyCode.RightArrow))
        {
            indiceActual = (indiceActual + 1) % grid.instances.Length;
            EnfocarTeteraOrbital(indiceActual);
        }

        if (Input.GetKeyDown(KeyCode.LeftArrow))
        {
            indiceActual--;
            if (indiceActual < 0) indiceActual = grid.instances.Length - 1;
            EnfocarTeteraOrbital(indiceActual);
        }
    }

    void UpdateFPS()
    {
        if (Input.GetKeyDown(KeyCode.Space))
            camaraFPS.ModoLibre();

        if (Input.GetKeyDown(KeyCode.RightArrow))
        {
            indiceActual = (indiceActual + 1) % grid.instances.Length;
            EnfocarTeteraFPS(indiceActual);
        }

        if (Input.GetKeyDown(KeyCode.LeftArrow))
        {
            indiceActual--;
            if (indiceActual < 0) indiceActual = grid.instances.Length - 1;
            EnfocarTeteraFPS(indiceActual);
        }
    }

    void VerTodaLaEscena()
    {
        Vector3 centro = grid.transform.position + new Vector3(5f, 0f, 2.5f);
        camaraOrbital.CambiarObjetivo(centro, 15f);
    }

    void EnfocarTeteraOrbital(int i)
    {
        if (grid.instances[i] == null) return;
        camaraOrbital.CambiarObjetivo(
            grid.instances[i].transform.position + Vector3.up * 0.8f, 7f);
    }

    void EnfocarTeteraFPS(int i)
    {
        if (grid.instances[i] == null) return;
        Vector3 posTetera = grid.instances[i].transform.position;
        camaraFPS.EnfocarObjetivo(
            posTetera + new Vector3(0, 0.8f, -1.5f),
            posTetera + Vector3.up * 0.5f);
    }
}