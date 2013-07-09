<#
VS+MSBuild.psm1 - Visual Studio and MSBuild utilities.

Copyright (c) 2013 Precision Mojo, LLC.

This file is part of the Unity3D.DLLs project (< URL >) which is distributed under the MIT License.
Refer to the LICENSE.MIT.md document located in the project directory for licensing terms.

Several functions are copied from scripts found in David Fowler's NuGetPowerTools package (https://github.com/davidfowl/NuGetPowerTools).
NuGetPowerTools is licensed under the Apache License 2.0 (https://nuget.codeplex.com/license).
#>

function Get-Projects
{
	param
	(
		[Parameter(ValueFromPipelineByPropertyName=$true)]
		[String[]] $ProjectName
	)

	if ($ProjectName)
	{
		$projects = Get-Project $ProjectName
	}
	else
	{
		$projects = Get-Project -All
	}

	$projects
}

function Get-MSBuildProject
{
	param
	(
		[Parameter(ValueFromPipelineByPropertyName=$true)]
		[String[]] $ProjectName,
		[switch] $SpecifyUserProject
	)

	process
	{
		(Get-Projects $ProjectName) | % {
			if ($SpecifyUserProject)
			{
				$path = $_.FullName + ".user"
			}
			else
			{
				$path = $_.FullName
			}

			@([Microsoft.Build.Evaluation.ProjectCollection]::GlobalProjectCollection.GetLoadedProjects($path))[0]
		}
	}
}

function Get-MSBuildProperty
{
	param
	(
		[Parameter(Position=0, Mandatory=$true)]
		$Name,
		[Parameter(Position=1, ValueFromPipelineByPropertyName=$true)]
		[String[]] $ProjectName
	)

	$buildProject = Get-MSBuildProject $ProjectName
	$buildProject.GetProperty($Name)
}

function Set-MSBuildProperty
{
	param
	(
		[Parameter(Position=0, Mandatory=$true)]
		[string] $PropertyName,
		[Parameter(Position=1, Mandatory=$true)]
		[string] $PropertyValue,
		[Parameter(Position=2, ValueFromPipelineByPropertyName=$true)]
		[String[]] $ProjectName,
		[switch] $SpecifyUserProject
	)

	process
	{
		(Get-Projects $ProjectName) | % {
			$buildProject = $_ | Get-MSBuildProject -SpecifyUserProject:$SpecifyUserProject
			$buildProject.SetProperty($PropertyName, $PropertyValue) | Out-Null
			$_.Save()
		}
	}
}

function Set-MSBuildItemMetadata
{
	param
	(
		[Parameter(Position=0, Mandatory=$true)]
		[string] $MetadataName,
		[Parameter(Position=1, Mandatory=$true)]
		[string] $MetadataValue,
		[Parameter(Position=2, Mandatory=$true)]
		$ProjectItemElement
	)

	$metadata = $ProjectItemElement.Metadata | ? { $_.Name -eq $MetadataName }

	if ($metadata)
	{
		$metadata.Value = $MetadataValue
	}
	else
	{
		$ProjectItemElement.AddMetadata($MetadataName, $MetadataValue)
	}
}
