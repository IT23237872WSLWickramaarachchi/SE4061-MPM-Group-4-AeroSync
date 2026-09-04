using UnityEngine;
using System.Net;
using System.Net.Sockets;
using System.Text;

/// <summary>
/// AeroSyncUnityBridge sends a signal to the AeroSync Flutter application
/// over UDP to trigger wind simulations synchronized with the VR game.
/// </summary>
public class AeroSyncUnityBridge : MonoBehaviour
{
    [Header("AeroSync Configuration")]
    [Tooltip("Unique ID for this game/scene. Must match the 'Linked Game ID' in AeroSync.")]
    public string projectId = "EagleFlight01";

    [Tooltip("IP Address of the machine running AeroSync. 255.255.255.255 will broadcast to the local network.")]
    public string targetIP = "255.255.255.255";

    [Tooltip("UDP Port AeroSync is listening on (default 8052).")]
    public int targetPort = 8052;

    [Header("Debug")]
    [Tooltip("If true, prints a debug message to the console exactly when the signal is sent.")]
    public bool enableDebugLogging = true;

    private UdpClient _udpClient;

    private void Awake()
    {
        _udpClient = new UdpClient();
        // Enable broadcast if using the broadcast address
        if (targetIP == "255.255.255.255")
        {
            _udpClient.EnableBroadcast = true;
        }
    }

    /// <summary>
    /// Call this method (e.g., from an event or StartFlight) to trigger the wind sim in AeroSync.
    /// </summary>
    public void TriggerSync()
    {
        if (enableDebugLogging)
        {
            Debug.Log($"[AeroSyncUnityBridge] Sending GAME_START signal to AeroSync at {targetIP}:{targetPort} for Project ID: {projectId}");
        }

        try
        {
            // Create JSON payload
            string jsonPayload = $"{{\"action\":\"GAME_START\",\"projectId\":\"{projectId}\"}}";
            byte[] bytes = Encoding.UTF8.GetBytes(jsonPayload);

            // Send UDP packet
            IPEndPoint endPoint = new IPEndPoint(IPAddress.Parse(targetIP), targetPort);
            _udpClient.Send(bytes, bytes.Length, endPoint);
        }
        catch (System.Exception ex)
        {
            Debug.LogError($"[AeroSyncUnityBridge] Failed to send trigger to AeroSync: {ex.Message}");
        }
    }

    private void OnDestroy()
    {
        if (_udpClient != null)
        {
            _udpClient.Close();
        }
    }
}
