using System;
using UnityEngine;

public class Blob : MonoBehaviour
{
	[SerializeField] private Renderer _renderer;
	[SerializeField] private Node[] _nodes;

	private MaterialPropertyBlock _materialPropertyBlock;

	private void Awake()
	{
		_materialPropertyBlock = new MaterialPropertyBlock();
	}

	private void Update()
	{
		_materialPropertyBlock.Clear();

		foreach (var node in _nodes)
		{
			if (string.IsNullOrWhiteSpace(node.Name)) continue;
			if (node.Transform1 == null) continue;
			if (node.Transform2 == null) continue;

			Vector4 aR = node.Transform1.position;
			aR.w = node.Radius;
			_materialPropertyBlock.SetVector(node.Name + "_a_r", aR);

			var b = node.Transform2.position;
			_materialPropertyBlock.SetVector(node.Name + "_b", b);
		}
		
		_renderer.SetPropertyBlock(_materialPropertyBlock);
	}

	[Serializable]
	public struct Node
	{
		public string Name;
		public Transform Transform1;
		public Transform Transform2;
		public float Radius;
	}
}