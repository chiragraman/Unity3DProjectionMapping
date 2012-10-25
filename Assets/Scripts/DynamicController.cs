/*
Copyright (C) 2012 Chirag Raman

This file is part of Projection-Mapping-in-Unity3D.

Projection-Mapping-in-Unity3D is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Projection Mapping in Unity3D is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Projection-Mapping-in-Unity3D.  If not, see <http://www.gnu.org/licenses/>.
*/


using UnityEngine;
using System.Collections;


public class DynamicController : MonoBehaviour {
	
	SelectionManager manager;
	private Vector3 screenPoint;
	private Vector3 offset;
	
	void Start(){
		
		GameObject selectionManager = GameObject.Find("Selection Manager");
		manager = selectionManager.GetComponent<SelectionManager>();
		Debug.Log("Copyright (C) 2011,2012 Chirag Raman.");
		Debug.Log("This project is licensed under the GPL. For details refer to the file COPYING with this project.");
		
	}

	void OnMouseDown(){
		
		//Assign current controller index to selectionManager.activeIndex
		string name = gameObject.name;
		manager.indexChanged = true;
		manager.activeIndex =  int.Parse(name[13].ToString()) - 1;
		
		screenPoint = Camera.main.WorldToScreenPoint(gameObject.transform.position);
    	offset = gameObject.transform.position - Camera.main.ScreenToWorldPoint(new Vector3(Input.mousePosition.x, Input.mousePosition.y, screenPoint.z));
		
		
	}
	
	void OnMouseDrag(){
		
		Vector3 curScreenPoint = new Vector3(Input.mousePosition.x, Input.mousePosition.y, screenPoint.z);
    	Vector3 curPosition = Camera.main.ScreenToWorldPoint(curScreenPoint) + offset;
    	gameObject.transform.position = curPosition;
		
	}
}
