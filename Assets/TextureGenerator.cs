#if UNITY_EDITOR
using System;
using System.Collections.Generic;
using System.IO;
using UnityEngine;
using UnityEngine.Rendering;
using Sirenix.OdinInspector;

[ExecuteInEditMode]
public class TextureGenerator : SerializedMonoBehaviour
{
    public Mesh PreviewMesh;

    public Material Material;

    public Texture2D Texture;

    public Vector2 Scale = new Vector2(10, 10);

    public int TileCount = 1;

    public struct Flag
    {
        public string Name;
        public float Value;
    }

    public List<Flag> Flags = new List<Flag>();

    public void UpdateTexture(Texture2D texture)
    {
        Material.mainTexture = texture;
        Texture = texture;
    }

    public Vector2Int SaveTextureResolution = new Vector2Int(512, 512);
    public bool SaveAsSRGB = false;
    public bool EnableAlpha = false;
    public bool SaveAsR16 = false;

    [PropertyOrder(9)]
    [LabelWidth(120)]
    [PropertySpace(SpaceAfter = 10)]
    public string OutputTexturePath;

    RenderTexture _renderTex;
    Texture2D _tex;

    [Button]
    public void SaveGeneratedTexture()
    {
        if (_renderTex != null) _renderTex.Release();
        var colorSpace = SaveAsSRGB ? RenderTextureReadWrite.sRGB : RenderTextureReadWrite.Linear;
        var format = SaveAsR16 ? RenderTextureFormat.R16 : RenderTextureFormat.ARGB32;
        _renderTex = new RenderTexture(SaveTextureResolution.x, SaveTextureResolution.y, 16, format);
        _renderTex.wrapModeU = TextureWrapMode.Clamp;
        _renderTex.wrapModeV = TextureWrapMode.Clamp;
        _renderTex.Create();
        var texFormat = EnableAlpha ? TextureFormat.RGBA32 : TextureFormat.RGB24;
        if (SaveAsR16) texFormat = TextureFormat.R16;
        _tex = new Texture2D(_renderTex.width, _renderTex.height, texFormat, false, true);
        CommandBuffer cmd = new CommandBuffer();
        RenderTextureCommands(cmd, Camera.main);
        Graphics.ExecuteCommandBuffer(cmd);
        ScheduleSaveTexture();
    }

    MaterialPropertyBlock _block = null;
    void RenderTextureCommands(CommandBuffer cmd, Camera camera)
    {
        cmd.SetRenderTarget(_renderTex.colorBuffer, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
        cmd.ClearRenderTarget(false, true, Color.clear);

        var lookMatrix = Matrix4x4.LookAt(Vector3.zero, new Vector3(0f, 0f, 1f), Vector3.up);
        var scaleMatrix = Matrix4x4.TRS(Vector3.zero, Quaternion.identity, new Vector3(1f, 1f, -1f));
        var viewMatrix = scaleMatrix * lookMatrix.inverse;
        var projectionMatrix = Matrix4x4.Ortho(-.5f, .5f, -.5f, .5f, -1f, 1f);
        cmd.SetViewProjectionMatrices(viewMatrix, projectionMatrix);

        if (_block == null) _block = new MaterialPropertyBlock();
        if (Texture != null) _block.SetTexture("_MainTex", Texture);
        for (int i = 0; i < Flags.Count; ++i) _block.SetFloat(Flags[i].Name, Flags[i].Value);
        var matrix = Matrix4x4.TRS(Vector3.zero, Quaternion.identity, Vector3.one);
        cmd.DrawMesh(PreviewMesh, matrix, Material, 0, 0, _block);
    }

    int _saveTextureDelay;

    // Need to wait a few frames after rendering to the RenderTexture before it's ready to read.
    void ScheduleSaveTexture()
    {
        _saveTextureDelay = 0;
        UnityEditor.EditorApplication.update += DelayedSaveTexture;
    }

    void DelayedSaveTexture()
    {
        ++_saveTextureDelay;
        if (_saveTextureDelay == 3)
        {
            SaveRenderTexture();
            UnityEditor.EditorApplication.update -= DelayedSaveTexture;
        }
    }

    void CopyRenderTexture()
    {
        RenderTexture.active = _renderTex;
        _tex.ReadPixels(new Rect(0, 0, _renderTex.width, _renderTex.height), 0, 0);
    }

    string GetAbsoluteTexturePath()
    {
        return Path.Combine(Application.dataPath, OutputTexturePath);
    }

    void SaveRenderTexture()
    {
        CopyRenderTexture();
        byte[] bytes = _tex.EncodeToPNG();
        if (!OutputTexturePath.EndsWith(".png")) OutputTexturePath += ".png";
        var path = GetAbsoluteTexturePath();
        File.WriteAllBytes(path, bytes);
        Debug.Log($"Wrote texture to {path}");
        _renderTex.Release();
        _renderTex = null;
        DestroyImmediate(_tex);
        UnityEditor.AssetDatabase.Refresh();
    }

    void Update()
    {
        Draw(Camera.main);
    }

    void OnEnable()
    {
        UnityEditor.SceneView.duringSceneGui += OnSceneGUI;
    }

    void OnDisable()
    {
        UnityEditor.SceneView.duringSceneGui -= OnSceneGUI;
    }

    void OnSceneGUI(UnityEditor.SceneView sceneView)
    {
        Draw(sceneView.camera);
    }

    void Draw(Camera camera)
    {
        if (PreviewMesh != null && Material != null)
        {
            if (_block == null) _block = new MaterialPropertyBlock();
            if (Texture != null) _block.SetTexture("_MainTex", Texture);
            for (int i = 0; i < Flags.Count; ++i) _block.SetFloat(Flags[i].Name, Flags[i].Value);
            Vector3 startPoint = -Scale * (TileCount - 1) * .5f;
            Vector3 meshScale = Scale;
            var extents = PreviewMesh.bounds.extents;
            meshScale.x /= extents.x * 2;
            meshScale.y /= extents.y * 2;
            for (int x = 0; x < TileCount; ++x)
            {
                for (int y = 0; y < TileCount; ++y)
                {
                    Vector3 offset = new Vector3(x * Scale.x, y * Scale.y, 0);
                    var trs = Matrix4x4.TRS(startPoint + offset + transform.position, Quaternion.identity, meshScale);
                    Graphics.DrawMesh(PreviewMesh, trs, Material, 0, camera, 0, _block);
                }
            }
        }
    }
}
#endif
