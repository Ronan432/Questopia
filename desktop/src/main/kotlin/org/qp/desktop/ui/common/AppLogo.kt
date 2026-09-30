package org.qp.desktop.ui.common

import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.SportsEsports
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.toComposeImageBitmap
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import java.io.InputStream
import javax.imageio.ImageIO

@Composable
fun DesktopAppLogo(
    size: Dp = 44.dp,
    modifier: Modifier = Modifier
) {
    val bitmap = remember {
        try {
            val stream: InputStream? = object {}.javaClass.getResourceAsStream("/app_logo.png")
                ?: object {}.javaClass.getResourceAsStream("/icon.png")
            if (stream != null) {
                val buffered = ImageIO.read(stream)
                buffered.toComposeImageBitmap()
            } else null
        } catch (e: Throwable) {
            null
        }
    }

    if (bitmap != null) {
        Image(
            bitmap = bitmap,
            contentDescription = "Questopia Logo",
            modifier = modifier
                .size(size)
                .clip(CircleShape)
        )
    } else {
        Surface(
            shape = CircleShape,
            color = MaterialTheme.colorScheme.primary,
            modifier = modifier.size(size)
        ) {
            Box(contentAlignment = Alignment.Center) {
                Icon(
                    imageVector = Icons.Filled.SportsEsports,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.onPrimary,
                    modifier = Modifier.size(size * 0.55f)
                )
            }
        }
    }
}
