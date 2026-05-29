using UnityEngine;

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
