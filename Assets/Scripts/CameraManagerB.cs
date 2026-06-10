using System.Collections;
using System.Collections.Generic;
using UnityEngine;


/*
/// <summary>
/// Manager de camaras para la Escena B.
/// 
/// SETUP EN UNITY:
///   1. Arrastra la camara orbital  -> campo "camaraOrbital"
///   2. Arrastra la camara FPS      -> campo "camaraFPS"
///   3. Asigna "centroEscena"       -> punto central de toda la escena (Vector3)
///   4. Asigna "distanciaEscena"    -> distancia inicial para ver toda la escena
///   5. En "puntosDeInteres" agrega los Transform de los objetos importantes
///      (la ventana, el sillon, el escritorio, lo que quieras)
///      Cada uno puede tener su propia distancia de zoom en "distanciasPOI"
///
/// CONTROLES:
///   P            -> alternar Orbital / FPS
///   Space        -> orbital: volver a ver toda la escena
///   Flecha Der.  -> orbital: enfocar siguiente punto de interes
///   Flecha Izq.  -> orbital: enfocar punto de interes anterior
///   Click Der.   -> rotar camara (ambos modos)
///   Rueda        -> zoom (modo orbital)
///   WASD         -> moverse (modo FPS)
///   E / Q        -> subir / bajar (modo FPS)
/// </summary>
public class CameraManagerB : MonoBehaviour


{
    [Header("Camaras")]
    public COB       camaraOrbital;
    public CamaraFPS camaraFPS;

    [Header("Vista general de la escena")]
    public Vector3 centroEscena      = Vector3.zero;
    public float   distanciaEscena   = 80f;

    [Header("Puntos de interes (objetos importantes)")]
    public Transform[] puntosDeInteres;
    // Distancia de zoom para cada punto. Si esta vacio usa distanciaDefectoPOI para todos.
    public float[]     distanciasPOI;
//dos nuevos
    public Vector3 posicionPelota = new Vector3(4.525f, 0.364f, -1.265f);
public float distanciaPelota = 5f;

    public float       distanciaDefectoPOI = 8f;
    // Offset vertical para que la camara mire un poco arriba del pivote del objeto
    public float       offsetVerticalPOI   = 0.8f;

    [Header("Posicion inicial FPS")]
    // Desde donde aparece la camara FPS al activarse
    public Vector3 posInicialFPS    = new Vector3(0f, 1.6f, -5f);
    public Vector3 mirarHaciaFPS    = Vector3.zero;

    // -------------------------------------------------------
    private int  indiceActual = -1;
    private bool modoFPS      = false;

    void Start()
    {
        VerTodaLaEscena();
        camaraFPS.gameObject.SetActive(false);
    }

    void Update()
    {
        // P -> alternar orbital / FPS
        if (Input.GetKeyDown(KeyCode.P))
            CambiarModo();

        if (!modoFPS)
            ControlesOrbital();
    }

    // -------------------------------------------------------

    void CambiarModo()
    {
        modoFPS = !modoFPS;
        camaraOrbital.gameObject.SetActive(!modoFPS);
        camaraFPS.gameObject.SetActive(modoFPS);

        if (modoFPS)
            camaraFPS.Teleportar(posInicialFPS, mirarHaciaFPS);
    }

    void ControlesOrbital()
    {
        // Space -> ver toda la escena
        if (Input.GetKeyDown(KeyCode.Space))
        {
            indiceActual = -1;
            VerTodaLaEscena();
        }

        // Flechas -> recorrer puntos de interes
        if (puntosDeInteres == null || puntosDeInteres.Length == 0) return;

        if (Input.GetKeyDown(KeyCode.RightArrow))
        {
            indiceActual = (indiceActual + 1) % puntosDeInteres.Length;
            EnfocarPOI(indiceActual);
        }

        if (Input.GetKeyDown(KeyCode.LeftArrow))
        {
            indiceActual--;
            if (indiceActual < 0) indiceActual = puntosDeInteres.Length - 1;
            EnfocarPOI(indiceActual);
        }
    }

    void VerTodaLaEscena()
    {
        camaraOrbital.CambiarObjetivo(centroEscena, distanciaEscena);
    }

    void EnfocarPOI(int i)
    {
        if (puntosDeInteres[i] == null) return;

        Vector3 pos  = puntosDeInteres[i].position + Vector3.up * offsetVerticalPOI;
        float   dist = ObtenerDistanciaPOI(i);

        camaraOrbital.CambiarObjetivo(pos, dist);
    }

    float ObtenerDistanciaPOI(int i)
    {
        if (distanciasPOI != null && i < distanciasPOI.Length && distanciasPOI[i] > 0f)
            return distanciasPOI[i];
        return distanciaDefectoPOI;
    }
}

*/

public class CameraManagerB : MonoBehaviour
{
    [Header("Camaras")]
    public COB camaraOrbital;
    public CamaraFPS camaraFPS;

    [Header("Vista general de la escena")]
    public Vector3 centroEscena = Vector3.zero;
    public float distanciaEscena = 10f;



    [Header("POIs")]
    public Transform[] puntosDeInteres;
    public float[] distanciasPOI;
    public float distanciaDefectoPOI = 8f;
    public float offsetVerticalPOI = 0.8f;

    [Header("Pelota (atajo teclado 1)")]
    public Vector3 posicionPelota = new Vector3(4.525f, 0.364f, -1.265f);
    public float distanciaPelota = 1f;

    [Header("Adorno (atajo teclado 2)")]
public Vector3 posicionAdorno = new Vector3(4.706f, 5.5f, 1.89f);
public float distanciaAdorno = 5f;

    [Header("FPS")]
    public Vector3 posInicialFPS = new Vector3(0f, 1.6f, -5f);
    public Vector3 mirarHaciaFPS = Vector3.zero;

    private int indiceActual = -1;
    private bool modoFPS = false;

    void Start()
    {
        VerTodaLaEscena();
        camaraFPS.gameObject.SetActive(false);
    }

    void Update()
    {
        // Cambiar modo
        if (Input.GetKeyDown(KeyCode.P))
            CambiarModo();

        // ATAJO: enfocar pelota
        if (Input.GetKeyDown(KeyCode.Alpha1))
        {
            EnfocarPelota();
        }
        if (Input.GetKeyDown(KeyCode.Alpha2))
{
    EnfocarAdorno();
}

        if (!modoFPS)
            ControlesOrbital();
    }

    // ---------------- MODOS ----------------

    void CambiarModo()
    {
        modoFPS = !modoFPS;

        camaraOrbital.gameObject.SetActive(!modoFPS);
        camaraFPS.gameObject.SetActive(modoFPS);

        if (modoFPS)
            camaraFPS.Teleportar(posInicialFPS, mirarHaciaFPS);
    }

    // ---------------- ORBITAL ----------------

    void ControlesOrbital()
    {
        if (Input.GetKeyDown(KeyCode.Space))
        {
            indiceActual = -1;
            VerTodaLaEscena();
        }

        if (puntosDeInteres == null || puntosDeInteres.Length == 0)
            return;

        if (Input.GetKeyDown(KeyCode.RightArrow))
        {
            indiceActual = (indiceActual + 1) % puntosDeInteres.Length;
            EnfocarPOI(indiceActual);
        }

        if (Input.GetKeyDown(KeyCode.LeftArrow))
        {
            indiceActual--;
            if (indiceActual < 0)
                indiceActual = puntosDeInteres.Length - 1;

            EnfocarPOI(indiceActual);
        }
    }

    // ENFOQUES 

    void VerTodaLaEscena()
    {
        camaraOrbital.CambiarObjetivo(centroEscena, distanciaEscena);
    }

    void EnfocarPOI(int i)
    {
        if (puntosDeInteres[i] == null) return;

        Vector3 pos = puntosDeInteres[i].position + Vector3.up * offsetVerticalPOI;
        float dist = ObtenerDistanciaPOI(i);

        camaraOrbital.CambiarObjetivo(pos, dist);
    }

    void EnfocarPelota()
    {
        //  ESTO ES LO IMPORTANTE
        camaraOrbital.CambiarObjetivo(posicionPelota, distanciaPelota);
    }

void EnfocarAdorno()
{
    camaraOrbital.CambiarObjetivo(posicionAdorno, distanciaAdorno);
}
    float ObtenerDistanciaPOI(int i)
    {
        if (distanciasPOI != null &&
            i < distanciasPOI.Length &&
            distanciasPOI[i] > 0f)
            return distanciasPOI[i];

        return distanciaDefectoPOI;
    }
}